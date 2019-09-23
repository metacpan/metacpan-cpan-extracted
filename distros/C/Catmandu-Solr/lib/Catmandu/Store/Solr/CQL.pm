package Catmandu::Store::Solr::CQL
    ;    #TODO see Catmandu::Store::ElasticSearch::CQL

use Catmandu::Sane;
use CQL::Parser;
use Carp qw(confess);
use Catmandu::Util qw(:is require_package);
use Moo;

with 'Catmandu::Logger';

our $VERSION = "0.0304";

has parser  => (is => 'ro', lazy => 1, builder => '_build_parser');
has mapping => (is => 'ro');

my $any_field         = qr'^(srw|cql)\.(serverChoice|anywhere)$'i;
my $match_all         = qr'^(srw|cql)\.allRecords$'i;
my $distance_modifier = qr'\s*\/\s*distance\s*<\s*(\d+)'i;
my $reserved          = qr'[\+\-\&\|\!\(\)\{\}\[\]\^\"\~\*\?\:\\]';

sub _build_parser {
    CQL::Parser->new;
}

sub parse {
    my ($self, $query) = @_;
    $self->log->debug("cql query: $query");
    my $node = eval {$self->parser->parse($query)} or do {
        my $error = $@;
        $self->log->error("cql error: $error");
        die "cql error: $error";
    };
    my $solr_query = $self->visit($node);
    $self->log->debug("solr query: $solr_query");
    $solr_query;
}

sub escape_term {
    my $term = $_[0];
    $term =~ s/($reserved)/\\$1/g;
    $term;
}

sub quote_term {
    my $term = $_[0];
    $term = qq("$term") if $term =~ /\s/;
    $term;
}

sub visit {
    my ($self, $node) = @_;

    my $mapping = $self->mapping;
    my $indexes = $mapping ? $mapping->{indexes} : undef;

    if ($node->isa('CQL::TermNode')) {

        my $term = escape_term($node->getTerm);

        if ($term =~ $match_all) {
            return "*:*";
        }

        my $qualifier = $node->getQualifier;
        my $relation  = $node->getRelation;
        my @modifiers = $relation->getModifiers;
        my $base      = lc $relation->getBase;

        if ($base eq 'scr') {
            if ($mapping && $mapping->{default_relation}) {
                $base = $mapping->{default_relation};
            }
            else {
                $base = '=';
            }
        }

        #default field
        if ($qualifier =~ $any_field) {

            #set default field explicitely
            if ($mapping && $mapping->{default_index}) {
                $qualifier = $mapping->{default_index};
            }

            #make solr decide what the default field should be
            else {
                $qualifier = "";
            }
        }

        #field search: new way
        if ($indexes) {

            #empty qualifier: Solr should decide how to query
            if (is_string($qualifier)) {

                #change qualifier
                $qualifier = lc $qualifier;
                my $old_qualifier = $qualifier;
                $qualifier =~ s/(?<=[^_])_(?=[^_])//g
                    if $mapping->{strip_separating_underscores};
                unless ($qualifier eq $old_qualifier) {
                    $self->log->debug(
                        "value of qualifier '$old_qualifier' reset to '$qualifier' because of setting 'strip_separating_underscores'"
                    );
                }
                my $q_mapping = $indexes->{$qualifier}
                    or confess "cql error: unknown index $qualifier";
                $q_mapping->{op}->{$base}
                    or confess "cql error: relation $base not allowed";

                my $op = $q_mapping->{op}->{$base};

                $old_qualifier = $qualifier;
                if (ref $op && $op->{field}) {

                    $qualifier = $op->{field};

                }
                elsif ($q_mapping->{field}) {

                    $qualifier = $q_mapping->{field};

                }

                unless ($qualifier eq $old_qualifier) {
                    $self->log->debug(
                        "value of qualifier '$old_qualifier' reset to '$qualifier' because of field mapping"
                    );
                }

                #add solr ':'
                $qualifier = "$qualifier:";

                #change term using filters
                my $filters;
                if (ref $op && $op->{filter}) {

                    $filters = $op->{filter};

                }
                elsif ($q_mapping->{filter}) {

                    $filters = $q_mapping->{filter};

                }
                if ($filters) {
                    for my $filter (@$filters) {
                        if ($filter eq 'lowercase') {
                            $self->log->debug(
                                "term '$term' filtered to lowercase");
                            $term = lc $term;
                        }
                    }
                }

                #change term using callbacks
                if (ref $op && $op->{cb}) {
                    my ($pkg, $sub) = @{$op->{cb}};
                    $self->log->debug(
                        "term '$term' changed to ${pkg}->${sub}");
                    $term = require_package($pkg)->$sub($term);
                }
                elsif ($q_mapping->{cb}) {
                    my ($pkg, $sub) = @{$q_mapping->{cb}};
                    $self->log->debug(
                        "term '$term' changed to ${pkg}->${sub}");
                    $term = require_package($pkg)->$sub($term);
                }

            }

        }

        #field search: old way
        else {
            #add solr ':'
            $qualifier = "$qualifier:" if is_string $qualifier;
        }

        if ($base eq '=' or $base eq 'scr') {
            $term = quote_term($term);
            for my $m (@modifiers) {
                if ($m->[1] eq 'fuzzy') {
                    return "$qualifier$term~";
                }
            }
            return $qualifier . $term;
        }
        elsif ($base eq '<') {
            $term = quote_term($term);
            return $qualifier . "{* TO $term}";
        }
        elsif ($base eq '>') {
            $term = quote_term($term);
            return $qualifier . "{$term TO *}";
        }
        elsif ($base eq '<=') {
            $term = quote_term($term);
            return $qualifier . "[* TO $term]";
        }
        elsif ($base eq '>=') {
            $term = quote_term($term);
            return $qualifier . "[$term TO *]";
        }
        elsif ($base eq '<>') {
            $term = quote_term($term);
            return "-$qualifier$term";
        }
        elsif ($base eq 'exact') {
            return $qualifier . quote_term($term);
        }
        elsif ($base eq 'all') {
            my @terms = split /\s+/, $term;
            if (@terms == 1) {
                return $qualifier . $term;
            }
            $term = join ' ', map {"+$_"} @terms;
            if ($qualifier) {
                return "$qualifier($term)";
            }
            return $term;
        }
        elsif ($base eq 'any') {
            $term = join ' OR ', map {$qualifier . $_} split /\s+/, $term;
            return "( $term)";
        }
        elsif ($base eq 'within') {
            my @range = split /\s+/, $term;
            if (@range == 1) {
                return $qualifier . $term;
            }
            else {
                return $qualifier . "[$range[0] TO $range[1]]";
            }
        }
        else {
            return $qualifier . quote_term($term);
        }
    }

    #TODO: apply cql_mapping
    elsif ($node->isa('CQL::ProxNode')) {
        my $distance  = 1;
        my $qualifier = $node->left->getQualifier;
        my $term      = escape_term(
            join(' ', $node->left->getTerm, $node->right->getTerm));

        if (my ($n) = $node->op =~ $distance_modifier) {
            $distance = $n if $n > 1;
        }
        if ($qualifier =~ $any_field) {
            return qq("$term"~$distance);
        }
        else {
            return qq($qualifier:"$term"~$distance);
        }
    }

    elsif ($node->isa('CQL::BooleanNode')) {
        my $lft   = $node->left;
        my $rgt   = $node->right;
        my $lft_q = $self->visit($lft);
        my $rgt_q = $self->visit($rgt);
        $lft_q = "( $lft_q)"
            unless $lft->isa('CQL::TermNode') || $lft->isa('CQL::ProxNode');
        $rgt_q = "( $rgt_q)"
            unless $rgt->isa('CQL::TermNode') || $rgt->isa('CQL::ProxNode');

        return join ' ', $lft_q, uc $node->op, $rgt_q;
    }
}

1;

=head1 NAME

Catmandu::Store::Solr::CQL - Converts a CQL query string to a Solr query string

=head1 SYNOPSIS

    $solr_query_string = Catmandu::Store::Solr::CQL->parse($cql_query_string);

=head1 DESCRIPTION

This package currently parses most of CQL 1.1:

    and
    or
    not
    prox
    prox/distance<$n
    srw.allRecords
    srw.serverChoice
    srw.anywhere
    cql.allRecords
    cql.serverChoice
    cql.anywhere
    =
    scr
    =/fuzzy
    scr/fuzzy
    <
    >
    <=
    >=
    <>
    exact
    all
    any
    within

=head1 METHODS

=head2 parse

Parses the given CQL query string with L<CQL::Parser> and converts it to a Solr query string.

=head2 visit

Converts the given L<CQL::Node> to a Solr query string.

=head1 TODO

support cql 1.2, more modifiers (esp. masked), sortBy, encloses

=head1 SEE ALSO

L<CQL::Parser>.

=cut
