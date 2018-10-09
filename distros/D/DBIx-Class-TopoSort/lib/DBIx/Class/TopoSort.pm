# vim: set noai ts=4 sw=4:
package DBIx::Class::TopoSort;

use 5.008_004;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.050100';

use Graph;

# Even though JSON::MaybeXS is recommended, DBIx::Class already uses JSON::Any,
# so we can depend on it existing in the world.
# Note: We cannot use JSON::DWIW because it does not provide a canonical()
# method. We need this in order to ensure the same hash is encoded the same way
# every time. Otherwise, preserve the order provided.
use JSON::Any qw(CPANEL XS JSON PP);
use Memoize qw(memoize unmemoize);
use Scalar::Util qw(reftype);

my $MEMOIZED = 0;
sub enable_toposort_memoize {
    disable_toposort_memoize() if $MEMOIZED;

    shift;
    my ($normalizer) = @_;
    $normalizer ||= sub {
        my @keys = (
            $$,
        );

        # toposort() could be called either as $schema->toposort(%opts) or as
        # DBIx::Class::TopoSort->toposort($schema, %opts)
        my $schema = shift;
        unless (ref($schema) && $schema->isa('DBIx::Class::Schema')) {
            $schema = shift;
        }

        # If you give me a $schema object, the graph is going to be the same
        # for every instance of that schema, so we can use the schema's class
        # for the anchor.
        push @keys, reftype($schema);

        # We need to track the %opts provided because invocations with different
        # parameters may result in different outputs.
        my %opts = @_;
        if (%opts) {
            push @keys, JSON::Any->new->canonical(1)->encode(\%opts);
        }

        return join ':', @keys;
    };

    $MEMOIZED = 1;
    memoize('DBIx::Class::TopoSort::toposort',
        NORMALIZER => $normalizer,
    );
}

sub disable_toposort_memoize {
    return unless $MEMOIZED;

    $MEMOIZED = 0;
    unmemoize('DBIx::Class::TopoSort::toposort');
}

sub toposort_graph {
    my $self = shift;
    my ($schema, %opts) = @_;

    my $g = Graph->new;

    my @source_names = $schema->sources;

    my %table_sources;
    foreach my $name ( @source_names ) {
        my $table_name = $schema->source($name)->name;
        $table_sources{$table_name} //= [];
        push @{ $table_sources{$table_name} }, $name;
    }

    foreach my $name ( @source_names ) {
        my $source = $schema->source($name);
        $g->add_vertex($name);

        foreach my $rel_name ( $source->relationships ) {
            next if grep { $_ eq $rel_name } @{$opts{skip}{$name}};
            my $rel_info = $source->relationship_info($rel_name);

            if ( $rel_info->{attrs}{is_foreign_key_constraint} ) {
                my $sources = $table_sources{$schema->source($rel_info->{source})->name};
                foreach my $source ( @$sources ) {
                    $g->add_edge($source, $name);
                }
            }
        }
    }

    if ($opts{detect_cycle}) {
        my @cycle = $g->find_a_cycle;
        die 'Found circular relationships between [' . join(', ', @cycle) . ']'
            if @cycle;
    }

    return $g;
}

sub toposort {
    my $self = shift;
    my $schema;
    if (ref($self) && $self->isa('DBIx::Class::Schema')) {
        $schema = $self;
    }
    else {
        $schema = shift(@_);
    }
    return $self->toposort_graph($schema, @_)->toposort();
}

1;
__END__

=head1 NAME

DBIx::Class::TopoSort - The addition of topological sorting to DBIx::Class

=head1 SYNOPSIS

Within your schema class:

  __PACKAGE__->load_components('TopoSort');

Later:

  my $schema = Your::App::Schema->connect(...);
  my @toposorted_sourcenames = $schema->toposort();

If you have a cycle in your relationships

  my @toposorted_sourcenames = $schema->toposort(
      skip => {
          Artist => [qw/ first_album /],
      },
  );

Alternately:

  my @toposorted_sourcenames = DBIx::Class::TopoSort->toposort($schema);

=head1 DESCRIPTION

This adds a method to L<DBIx::Class::Schema> which returns the full list of
sources (similar to L<DBIx::Class::Schema/sources>) in topological-sorted order.

=head2 TOPOLOGICAL SORT

A topological sort of the tables returns the list of tables such that any table
with a foreign key relationship appears after any table it has a foreign key
relationship to.

=head1 METHODS

This class is not instantiable nor does it provide any methods of its own. All
methods are added to the L<DBIx::Class::Schema> class and are callable on
objects instantiated of that class.

=head2 toposort

This is sugar for:

  $self->toposort_graph(@_)->toposort();

Calling this method multiple times may return the list of source names in
different order. Each order will conform to the gurantee described in the
section on TOPOLOGICAL SORT.

This method will throw an error if there are any cycles in your tables. You will
need to specify the skip parameter (described below) to break those cycles.

=head2 toposort (Class method)

Alternately, if you do not wish to use TopoSort as a component, you can call it
as a class method on this class. The toposort() method is smart enough to
distinguish.

Note: toposort_graph() does B<not> distinguish - it assumes it will be called
with the C<$schema> object passed in.

=head2 toposort_graph

This returns a L<Graph> object with a vertex for every source and an edge for
every foreign key relationship.

It takes the following parameters.

=over 4

=item skip

This describes the list of relationships that should be ignored by the toposort
algorithm. This is generally used if you have cycles in your schema (though it
could possibly be useful in other ways, I guess). The value is a hashref. The
keys of this hashref are source names and the values are arrays of relationship
names.

  skip => {
      Artist => [ qw/ first_album / ],
  },

=item detect_cycle

If this is true, then L<Graph/find_a_cycle> will be called and, if a cycle is
found, this will die detailing the cycle found.

This is useful because the L<Graph/toposort> method dies with a cyclic
graph, but doesn't tell you what any of the cycles are that killed it.

B<NOTE>: Finding cycles can be expensive. Don't do this on a regular basis.

=back

=head2 enable_toposort_memoize (Class method)

This will L<Memoize/memoize> the L</toposort> function. By default, it uses a
normalizer function that concatenates the following (in order):

=over 4

=item * The PID of this process

=item * The class of the schema

=item * The canonicalized JSON of any options provided.

=back

You may pass in a different function if you need to.

=head2 disable_toposort_memoize (Class method)

This will disable any memoize on L</toposort>. Unlike L<Memoize/unmemoize>, this
will not croak if you haven't already memoized.

=head1 SEE ALSO

L<Graph/toposort>

=head1 AUTHOR

=over 4

=item * Rob Kinyon <rob.kinyon@gmail.com>

=back

=head1 CONTRIBUTIONS

Contributions have been generously donated by ZipRecruiter.

=head1 LICENSE

Copyright (c) 2013 Rob Kinyon. All Rights Reserved.
This is free software, you may use it and distribute it under the same terms
as Perl itself.

=cut
