package Catmandu::Store::MongoDB::CQL;

use Catmandu::Sane;
use CQL::Parser;
use Carp qw(confess);
use Catmandu::Util qw(:is array_includes require_package);
use Data::Dumper;
use Moo;

with 'Catmandu::Logger';

has parser  => (is => 'ro', lazy => 1, builder => '_build_parser');
has mapping => (is => 'ro');

my $any_field = qr'^(srw|cql)\.(serverChoice|anywhere)$'i;
my $match_all = qr'^(srw|cql)\.allRecords$'i;

sub _build_parser {
    CQL::Parser->new;
}

sub parse {
    my ($self, $query) = @_;

    my $node = eval {$self->parser->parse($query)} or do {
        my $error = $@;
        die "cql error: $error";
    };

    my $mongo_query = $self->visit($node);

    if ($self->log->is_debug()) {

        $self->log->debug("CQL query: $query, translated into mongo query: "
                . Dumper($mongo_query));

    }

    $mongo_query;
}

sub visit {
    my ($self, $node) = @_;

    my $indexes = $self->mapping ? $self->mapping->{indexes} : undef;

    confess "no cql_mapping.indexes defined" unless $indexes;

    if ($node->isa('CQL::TermNode')) {
        my $term = $node->getTerm;

        if ($term =~ $match_all) {
            return +{};
        }

        my $qualifier = $node->getQualifier;
        my $relation  = $node->getRelation;
        my @modifiers = $relation->getModifiers;
        my $base      = lc $relation->getBase;
        my $search_field;
        my $search_clause;

        if ($base eq 'scr') {
            if ($self->mapping && $self->mapping->{default_relation}) {
                $base = $self->mapping->{default_relation};
            }
            else {
                $base = '=';
            }
        }

        #fields to search for
        if ($qualifier =~ $any_field) {

            #set default field explicitely
            if ($self->mapping && $self->mapping->{default_index}) {
                $search_field = $self->mapping->{default_index};
            }
            else {
                $search_field = '_all';
            }
        }
        else {
            $search_field = $qualifier;

            #change search field
            $search_field =~ s/(?<=[^_])_(?=[^_])//g
                if $self->mapping
                && $self->mapping->{strip_separating_underscores};
            my $q_mapping = $indexes->{$search_field}
                or confess "cql error: unknown index $search_field";
            $q_mapping->{op}->{$base}
                or confess "cql error: relation $base not allowed";

            my $op = $q_mapping->{op}->{$base};

            if (ref $op && $op->{field}) {
                $search_field = $op->{field};
            }
            elsif ($q_mapping->{field}) {
                $search_field = $q_mapping->{field};
            }

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
                        $term = lc $term;
                    }
                }
            }

            #change term using callbacks
            if (ref $op && $op->{cb}) {
                my ($pkg, $sub) = @{$op->{cb}};
                $term = require_package($pkg)->$sub($term);
            }
            elsif ($q_mapping->{cb}) {
                my ($pkg, $sub) = @{$q_mapping->{cb}};
                $term = require_package($pkg)->$sub($term);
            }
        }

        #field search
        my $unmasked
            = array_includes([map {$_->[1]} @modifiers], "cql.unmasked");

        # trick to force numeric values interpreted as integers
        $term = $term + 0 if ($term =~ /^[1-9]\d*$/);

        if ($base eq '=' or $base eq 'scr') {
            unless ($unmasked) {
                $term
                    = _is_wildcard($term) ? _wildcard_to_regex($term) : $term;
            }

            $search_clause = +{$search_field => $term};
        }
        elsif ($base eq '<') {
            $search_clause = +{$search_field => {'$lt' => $term}};
        }
        elsif ($base eq '>') {
            $search_clause = +{$search_field => {'$gt' => $term}};
        }
        elsif ($base eq '<=') {
            $search_clause = +{$search_field => {'$lte' => $term}};
        }
        elsif ($base eq '>=') {
            $search_clause = +{$search_field => {'$gte' => $term}};
        }
        elsif ($base eq '<>') {
            $search_clause = +{$search_field => {'$ne' => $term}};
        }
        elsif ($base eq 'exact') {
            $search_clause = +{$search_field => $term};
        }
        elsif ($base eq 'all') {
            my @terms = split /\s+/, $term;

#query $all in mongo means exact matching, so we always need regular expressions here
            for (my $i = 0; $i < scalar(@terms); $i++) {

                my $term = $terms[$i];

                if ($unmasked) {

                    $term = _quote_wildcard($term);
                    $term = qr($term);

                }
                elsif (_is_wildcard($term)) {

                    $term = _wildcard_to_regex($term);

                }
                else {

                    $term = qr($term);

                }

                $terms[$i] = $term;

            }

            $search_clause = +{$search_field => {'$all' => \@terms}};
        }
        elsif ($base eq 'any') {
            my @terms = split /\s+/, $term;

#query $in in mongo means exact matching, so we always need regular expressions here
            for (my $i = 0; $i < scalar(@terms); $i++) {

                my $term = $terms[$i];

                if ($unmasked) {

                    $term = _quote_wildcard($term);
                    $term = qr($term);

                }
                elsif (_is_wildcard($term)) {

                    $term = _wildcard_to_regex($term);

                }
                else {

                    $term = qr($term);

                }

                $terms[$i] = $term;

            }

            $search_clause = +{$search_field => {'$in' => \@terms}};
        }
        elsif ($base eq 'within') {
            my @range = split /\s+/, $term;

            if (@range == 1) {
                $search_clause = +{$search_field => $term};
            }
            else {
                $search_clause
                    = +{$search_field =>
                        {'$gte' => $range[0], '$lte' => $range[1]}
                    };
            }
        }

        #as $base is always set, this code should be removed?
        else {
            unless ($unmasked) {
                $term
                    = _is_wildcard($term) ? _wildcard_to_regex($term) : $term;
            }

            $search_clause = +{$search_field => $term};
        }

        return $search_clause;
    }
    elsif ($node->isa('CQL::ProxNode')) {

        # TODO: apply cql_mapping
        confess "not supported";
    }
    elsif ($node->isa('CQL::BooleanNode')) {
        my $lft   = $node->left;
        my $rgt   = $node->right;
        my $lft_q = $self->visit($lft);
        my $rgt_q = $self->visit($rgt);
        my $op    = '$' . lc($node->op);

        if ($op eq '$and' || $op eq '$or') {
            return +{$op => [$lft_q, $rgt_q]};
        }
        elsif ($op eq '$not') {
            my ($k, $v) = each(%$rgt_q);

            if ($k eq '$or') {
                return +{%$lft_q, '$nor' => $v};
            }
            elsif ($k eq '$and') {

     #$nand not implemented yet (https://jira.mongodb.org/browse/SERVER-15577)
                return +{%$lft_q, '$nor' => [{'$and' => $v}]};
            }
            else {
                return +{%$lft_q, '$nor' => [{'$and' => [{$k => $v}]}]};
            }
        }
    }
}

sub _is_wildcard {
    my $value = $_[0];

           (index($value, '^') == 0)
        || (rindex($value, '^') == length($value) - 1)
        || (index($value, '*') >= 0)
        || (index($value, '?') >= 0);
}

sub _wildcard_to_regex {
    my $value = $_[0];
    my $regex = $value;
    $regex =~ s/\*/.*/go;
    $regex =~ s/\?/.?/go;
    $regex =~ s/\^$/\$/o;
    qr/$regex/;
}

sub _quote_wildcard {
    my $value = $_[0];
    $value =~ s/\*/\\*/go;
    $value =~ s/\?/\\?/go;
    $value =~ s/\^/\\^/go;
    $value;
}

1;

__END__

=head1 NAME

Catmandu::Store::MongoDB::CQL - Converts a CQL query string to a MongoDB query string

=head1 SYNOPSIS

    $mongo_query = Catmandu::Store::ElasticSearch::CQL
                    ->new(mapping => $cql_mapping)
                    ->parse($cql_query_string);

=head1 DESCRIPTION

This package currently parses most of CQL 1.1:

    and
    or
    not
    srw.allRecords
    srw.serverChoice
    srw.anywhere
    cql.allRecords
    cql.serverChoice
    cql.anywhere
    =
    scr
    <
    >
    <=
    >=
    <>
    exact
    all
    any
    within

See L<https://www.loc.gov/standards/sru/cql/spec.html> for
more information on the CQL query language.

=head1 LIMITATIONS

MongoDB is not a full-text search engine. All queries will try to find exact
matches in the database, except for the 'any' and 'all' relations which will
translate queries into wildcard queries (which are slow!):

   title any 'funny cats'

will be treated internally as something like:

    title : { $regex : /funny/ } OR title : { $regex : /cats/ }

And,

    title all 'funny cats'

as

    title : { $regex : /funny/ } AND title : { $regex : /cats/ }

This makes the 'any' and 'all' not as efficient (fast) as exact matches
'==','exact'.

=head1 METHODS

=head2 parse

Parses the given CQL query string with L<CQL::Parser> and converts it to a Mongo query string.

=head2 visit

Converts the given L<CQL::Node> to a Mongo query string.

=head1 REMARKS

no support for fuzzy search, search modifiers, sortBy and encloses

=head1 SEE ALSO

L<CQL::Parser>.

=cut
