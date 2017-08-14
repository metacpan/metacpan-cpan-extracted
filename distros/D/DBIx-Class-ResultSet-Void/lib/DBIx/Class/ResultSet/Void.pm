package DBIx::Class::ResultSet::Void;
$DBIx::Class::ResultSet::Void::VERSION = '0.07';
# ABSTRACT: improve DBIx::Class::ResultSet with void context

use strict;
use warnings;
use Carp::Clan qw/^DBIx::Class/;
use Try::Tiny;

use base qw(DBIx::Class::ResultSet);

sub exists {
    my ($self, $query) = @_;

    return $self->search(
        $query,
        {
            rows   => 1,
            select => [\'1']})->single;
}

sub find_or_create {
    my $self = shift;

    return $self->next::method(@_) if (defined wantarray);

    my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
    my $hash = ref $_[0] eq 'HASH' ? shift : {@_};

    my $query = $self->___get_primary_or_unique_key($hash, $attrs);
    my $exists = $self->exists($query);
    $self->create($hash) unless $exists;
}

sub update_or_create {
    my $self = shift;

    return $self->next::method(@_) if (defined wantarray);

    my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});
    my $cond = ref $_[0] eq 'HASH' ? shift : {@_};

    my $query = $self->___get_primary_or_unique_key($cond, $attrs);
    my $exists = $self->exists($query);

    if ($exists) {
        # dirty hack, to remove WHERE cols from SET
        my $query_array = ref $query eq 'ARRAY' ? $query : [$query];
        foreach my $_query (@$query_array) {
            foreach my $_key (keys %$_query) {
                delete $cond->{$_key};
                delete $cond->{$1} if $_key =~ /\w+\.(\w+)/;    # $alias.$col
            }
        }
        $self->search($query)->update($cond) if keys %$cond;
    } else {
        $self->create($cond);
    }
}

# mostly copied from sub find
sub ___get_primary_or_unique_key {
    my $self = shift;
    my $attrs = (@_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {});

    my $rsrc = $self->result_source;

    my $constraint_name;
    if (exists $attrs->{key}) {
        $constraint_name =
            defined $attrs->{key}
            ? $attrs->{key}
            : $self->throw_exception("An undefined 'key' resultset attribute makes no sense");
    }

    # Parse out the condition from input
    my $call_cond;

    if (ref $_[0] eq 'HASH') {
        $call_cond = {%{$_[0]}};
    } else {
        # if only values are supplied we need to default to 'primary'
        $constraint_name = 'primary' unless defined $constraint_name;

        my @c_cols = $rsrc->unique_constraint_columns($constraint_name);

        $self->throw_exception("No constraint columns, maybe a malformed '$constraint_name' constraint?") unless @c_cols;

        $self->throw_exception('find() expects either a column/value hashref, or a list of values '
                . "corresponding to the columns of the specified unique constraint '$constraint_name'")
            unless @c_cols == @_;

        @{$call_cond}{@c_cols} = @_;
    }

    # process relationship data if any
    for my $key (keys %$call_cond) {
        if (
            length ref($call_cond->{$key})
            and my
            $relinfo = $rsrc->relationship_info($key)
            and
            # implicitly skip has_many's (likely MC)
            (ref(my $val = delete $call_cond->{$key}) ne 'ARRAY'))
        {
            my ($rel_cond, $crosstable) = $rsrc->_resolve_condition($relinfo->{cond}, $val, $key, $key);

            $self->throw_exception("Complex condition via relationship '$key' is unsupported in find()")
                if $crosstable
                or ref($rel_cond) ne 'HASH';

            # supplement condition
            # relationship conditions take precedence (?)
            @{$call_cond}{keys %$rel_cond} = values %$rel_cond;
        }
    }

    my $alias = exists $attrs->{alias} ? $attrs->{alias} : $self->{attrs}{alias};
    my $final_cond;
    if (defined $constraint_name) {
        $final_cond = $self->_qualify_cond_columns(

            $self->result_source->_minimal_valueset_satisfying_constraint(
                constraint_name => $constraint_name,
                values          => ($self->_merge_with_rscond($call_cond))[0],
                carp_on_nulls   => 1,
            ),

            $alias,
        );
    } elsif ($self->{attrs}{accessor} and $self->{attrs}{accessor} eq 'single') {
        # This means that we got here after a merger of relationship conditions
        # in ::Relationship::Base::search_related (the row method), and furthermore
        # the relationship is of the 'single' type. This means that the condition
        # provided by the relationship (already attached to $self) is sufficient,
        # as there can be only one row in the database that would satisfy the
        # relationship
    } else {
        my (@unique_queries, %seen_column_combinations, $ci, @fc_exceptions);

        # no key was specified - fall down to heuristics mode:
        # run through all unique queries registered on the resultset, and
        # 'OR' all qualifying queries together
        #
        # always start from 'primary' if it exists at all
        for my $c_name (sort { $a eq 'primary' ? -1 : $b eq 'primary' ? 1 : $a cmp $b } $rsrc->unique_constraint_names) {

            next if $seen_column_combinations{join "\x00", sort $rsrc->unique_constraint_columns($c_name)}++;

            try {
                push @unique_queries,
                    $self->_qualify_cond_columns(
                    $self->result_source->_minimal_valueset_satisfying_constraint(
                        constraint_name => $c_name,
                        values          => ($self->_merge_with_rscond($call_cond))[0],
                        columns_info    => ($ci ||= $self->result_source->columns_info),
                    ),
                    $alias
                    );
            }
            catch {
                push @fc_exceptions, $_ if $_ =~ /\bFilterColumn\b/;
            };
        }

        $final_cond =
              @unique_queries ? \@unique_queries
            : @fc_exceptions ? $self->throw_exception(join "; ", map { $_ =~ /(.*) at .+ line \d+$/s } @fc_exceptions)
            :                  $self->_non_unique_find_fallback($call_cond, $attrs);
    }

    return $final_cond;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::ResultSet::Void - improve DBIx::Class::ResultSet with void context

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $rs = $schema->resultset('CD');
    $rs->find_or_create( {
        artist => 'Massive Attack',
        title  => 'Mezzanine',
    } );

As ResultSet subclass in Schema.pm:

    __PACKAGE__->load_namespaces(
        default_resultset_class => '+DBIx::Class::ResultSet::Void'
    );

Or in Schema/CD.pm

    __PACKAGE__->resultset_class('DBIx::Class::ResultSet::Void');

Or in ResultSet/CD.pm

    use base 'DBIx::Class::ResultSet::Void';

=head1 DESCRIPTION

The API is the same as L<DBIx::Class::ResultSet>.

use C<exists> instead of C<find> unless defined wantarray.

(Thank ribasushi to tell me C<count> is bad)

=head2 METHODS

=over 4

=item * exists

    $rs->exists( { id => 1 } );

It works like:

    $rs->search( { id => 1 }, { rows => 1, select => [1] } )->single;

It is a little faster than C<count> if you don't care the real count.

=item * find_or_create

L<DBIx::Class::ResultSet/find_or_create>:

    $rs->find_or_create( { id => 1, name => 'A' } );

produces SQLs like:

    # SELECT me.id, me.name FROM item me WHERE ( me.id = ? ): '1'
    # INSERT INTO item ( id, name) VALUES ( ?, ? ): '1', 'A'

but indeed C<SELECT 1 ...  LIMIT 1> is performing a little better than me.id, me.name

this module L<DBIx::Class::ResultSet::Void> produces SQLs like:

    # SELECT 1 FROM item me WHERE ( me.id = ? ) LIMIT 1: '1'
    # INSERT INTO item ( id, name) VALUES ( ?, ? ): '1', 'A'

we would delegate it DBIx::Class::ResultSet under context like:

    my $row = $rs->find_or_create( { id => 1, name => 'A' } );

=item * update_or_create

L<DBIx::Class::ResultSet/update_or_create>:

    $rs->update_or_create( { id => 1, name => 'B' } );

produces SQLs like:

    # SELECT me.id, me.name FROM item me WHERE ( me.id = ? ): '1'
    # UPDATE item SET name = ? WHERE ( id = ? ): 'B', '1'

this module:

    # SELECT 1 FROM item me WHERE ( me.id = ? ) LIMIT 1: '1'
    # UPDATE item SET name = ? WHERE ( id = ? ): 'B', '1'

=back

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
