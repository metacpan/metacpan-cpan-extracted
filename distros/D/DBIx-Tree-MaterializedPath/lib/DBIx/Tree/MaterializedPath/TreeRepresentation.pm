package DBIx::Tree::MaterializedPath::TreeRepresentation;

use warnings;
use strict;

use Carp;

use Readonly;

use DBIx::Tree::MaterializedPath::Node;

=head1 NAME

DBIx::Tree::MaterializedPath::TreeRepresentation - data structure for "materialized path" trees

=head1 VERSION

Version 0.06

=cut

use version 0.74; our $VERSION = qv('0.06');

=head1 SYNOPSIS

    # Row data must be sorted by path:
    my $column_names = ['id', 'path', 'name'];
    my $subtree_data = [
                        [ 2, "1.1",     "a"],
                        [ 3, "1.2",     "b"],
                        [ 4, "1.3",     "c"],
                        [ 5, "1.3.1",   "d"],
                        [ 7, "1.3.1.1", "e"],
                        [ 6, "1.3.2",   "f"],
                       ];

    my $subtree_representation =
      DBIx::Tree::MaterializedPath::TreeRepresentation->new($node,
                                                            $column_names,
                                                            $subtree_data);

    $subtree_representation->traverse($coderef, $context);

=head1 DESCRIPTION

This module implements a data structure that represents a tree
(or subtree) as stored in the database.

B<Note:> Normally these objects would not be created independently
- call
L<get_descendants()|DBIx::Tree::MaterializedPath::Node/get_descendants>
on a
L<tree|DBIx::Tree::MaterializedPath>
or a
L<node|DBIx::Tree::MaterializedPath::Node>
to get its descendants as a
L<DBIx::Tree::MaterializedPath::TreeRepresentation|DBIx::Tree::MaterializedPath::TreeRepresentation>
object, and then
L<traverse()|/traverse>
those descendants.

=head1 METHODS

=head2 new

    $subtree_data =
      DBIx::Tree::MaterializedPath::TreeRepresentation->new($node,
                                                            $cols_listref,
                                                            $rows_listref,
                                                            $options_hashref);

C<new()> expects a
L<DBIx::Tree::MaterializedPath::Node|DBIx::Tree::MaterializedPath::Node>
object (representing the node that this data belongs to), a listref
of database column names, and a listref of listrefs, each of which
represents a node row in the database.

At minimum, each row must contain entries for the
L<id_column_name|DBIx::Tree::MaterializedPath/id_column_name>
and the
L<path_column_name|DBIx::Tree::MaterializedPath/path_column_name>
as specified in the
L<DBIx::Tree::MaterializedPath|DBIx::Tree::MaterializedPath>
constructor.  The rows should be sorted by path in ascending order.

Additionally, the row may contain entries for
any metadata columns which are stored with the nodes.

One L<DBIx::Tree::MaterializedPath::Node> object will be created in
the data structure for each input row.  If the optional parameters
hashref contains a true value for "B<ignore_empty_hash>", and if no
metadata entries exist in the input row, then the node object's
metadata will not be populated, and will only be retrieved
from the database when the L<data()|/data> method is called on a
given node.

=cut

sub new
{
    my ($class, $node, $column_names, $rows, @args) = @_;

    croak 'Missing node' unless $node;
    eval { ref($node) && $node->isa('DBIx::Tree::MaterializedPath::Node') }
      or
      do { croak 'Invalid node: not a "DBIx::Tree::MaterializedPath::Node"' };

    croak 'Missing column names' unless $column_names;
    croak 'Invalid column names' unless ref($column_names) eq 'ARRAY';

    croak 'Missing rows' unless $rows;
    croak 'Invalid rows' unless ref($rows) eq 'ARRAY';

    my $options = ref $args[0] eq 'HASH' ? $args[0] : {@args};

    my $ignore_empty_hash = $options->{ignore_empty_hash} ? 1 : 0;

    my $self = bless {}, ref($class) || $class;

    $self->{_node} = $node;

    # E.g. calling C<get_descendants()> on node "E" below:
    #
    #           A
    #        ___|_____
    #       |         |
    #       B         E
    #      _|_     ___|___
    #     |   |   |   |   |
    #     C   D   F   I   J
    #            _|_
    #           |   |
    #           G   H
    #
    # might produce column names that look like this:
    #
    # ['id', 'path', 'name']
    #
    # and database rows that look like this:
    #
    # [
    #   [  6, "1.2.1",   "F"],
    #   [  7, "1.2.1.1", "G"],
    #   [  8, "1.2.1.2", "H"],
    #   [  9, "1.2.2",   "I"],
    #   [ 10, "1.2.3",   "J"],
    # ]
    #
    # which results in the following data structure:
    #
    # [
    #   {
    #     node     => DBIx::Tree::MaterializedPath::Node "F",
    #     children => [
    #                   {
    #                     node     => DBIx::Tree::MaterializedPath::Node "G",
    #                     children => [],
    #                   },
    #                   {
    #                     node     => DBIx::Tree::MaterializedPath::Node "H",
    #                     children => [],
    #                   },
    #                 ],
    #   },
    #   {
    #     node     => DBIx::Tree::MaterializedPath::Node "I",
    #     children => [],
    #   },
    #   {
    #     node     => DBIx::Tree::MaterializedPath::Node "J",
    #     children => [],
    #   },
    # ]

    my $root = $node->get_root;

    my $num_nodes = 0;
    my @nodes     = ();

    if (@{$rows})
    {
        my $path_col = $root->{_path_column_name};

        my $ix_path_col = 0;
        my $found       = 0;
        foreach my $column_name (@{$column_names})
        {
            if ($column_name eq $path_col)
            {
                $found++;
                last;
            }
            $ix_path_col++;
        }
        croak 'Path column name not found' unless $found;

        my $path   = $rows->[0]->[$ix_path_col];
        my $length = length $path;

        _add_descendant_nodes(
                              {
                               prev_path   => q{},
                               prev_length => $length,
                               nodes       => \@nodes,
                              },
                              {
                               root              => $root,
                               ix_path_col       => $ix_path_col,
                               column_names      => $column_names,
                               num_nodes_ref     => \$num_nodes,
                               rows              => $rows,
                               ignore_empty_hash => $ignore_empty_hash
                              },
                             );
    }

    $self->{_descendants} = \@nodes;
    $self->{_num_nodes}   = $num_nodes;
    $self->{_has_nodes}   = $self->{_num_nodes} ? 1 : 0;

    return $self;
}

sub _add_descendant_nodes
{
    my ($args, $invariant_args) = @_;

    my $prev_path   = $args->{prev_path};
    my $prev_length = $args->{prev_length};
    my $nodes       = $args->{nodes};

    my $root              = $invariant_args->{root};
    my $ix_path_col       = $invariant_args->{ix_path_col};
    my $column_names      = $invariant_args->{column_names};
    my $num_nodes_ref     = $invariant_args->{num_nodes_ref};
    my $rows              = $invariant_args->{rows};
    my $ignore_empty_hash = $invariant_args->{ignore_empty_hash};

    my $node_children = undef;

    while (@{$rows})
    {
        my $path   = $rows->[0]->[$ix_path_col];
        my $length = length $path;

        # If path length is less, we've gone back up
        # a level in the tree:
        if ($length < $prev_length)
        {
            return;
        }

        # If path length is greater, we've gone down
        # a level in the tree:
        elsif ($length > $prev_length)
        {
            _add_descendant_nodes(
                                  {
                                   prev_path   => $prev_path,
                                   prev_length => $length,
                                   nodes       => $node_children,
                                  },
                                  $invariant_args,
                                 );
        }

        # If path length is the same, we're adding
        # siblings at the same level:
        else
        {
            my $row = shift @{$rows};

            if ($path eq $prev_path)
            {
                carp "Danger! Found multiple rows with path <$path>";
            }
            else
            {
                $prev_path = $path;
            }

            my %data = map { $_ => shift @{$row} } @{$column_names};
            my $child = DBIx::Tree::MaterializedPath::Node->new($root,
                     {data => \%data, ignore_empty_hash => $ignore_empty_hash});

            $node_children = [];
            push @{$nodes}, {node => $child, children => $node_children};
            ${$num_nodes_ref}++;
        }
    }

    return;
}

=head2 has_nodes

   $subtree_data->has_nodes()

Return true if the data structure contains any nodes.

=cut

sub has_nodes
{
    my ($self) = @_;
    return $self->{_has_nodes};
}

=head2 num_nodes

   $subtree_data->num_nodes()

Return the number of nodes in the data structure.

=cut

sub num_nodes
{
    my ($self) = @_;
    return $self->{_num_nodes};
}

=head2 traverse

    $subtree_data->traverse( $coderef, $optional_context )

Given a coderef, traverse down the data structure in leftmost
depth-first order and apply the coderef at each node.

The first argument to the I<$coderef> will be the node being
traversed.  The second argument to the I<$coderef> will be that
node's parent.

If supplied, I<$context> will be the third argument to the
coderef.  I<$context> can be a reference to a data structure that
can allow information to be carried along from node to node while
traversing the tree.

E.g. to count the number of descendants:

    my $context = {count => 0};
    my $coderef = sub {
        my ($node, $parent, $context) = @_;
        $context->{count}++;
    };

    my $descendants = $node->get_descendants();
    $descendants->traverse($coderef, $context);

    print "The node has $context->{count} descendants.\n";

Note that you may be able to use closure variables instead of
passing them along in I<$context>:

    my $count   = 0;
    my $coderef = sub {
        my ($node, $parent) = @_;
        $count++;
    };

    my $descendants = $node->get_descendants();
    $descendants->traverse($coderef, $context);

    print "The node has $count descendants.\n";

=cut

sub traverse
{
    my ($self, $coderef, $context) = @_;

    croak 'Missing coderef' unless $coderef;
    croak 'Invalid coderef' unless ref($coderef) eq 'CODE';

    return unless $self->{_has_nodes};
    $self->_traverse($self->{_node}, $self->{_descendants}, $coderef, $context);

    return;
}

sub _traverse
{
    my ($self, $parent, $descendants, $coderef, $context) = @_;

    foreach my $child (@{$descendants})
    {
        my $node = $child->{node};
        $coderef->($node, $parent, $context);

        my $children = $child->{children};
        if (@{$children})
        {
            $self->_traverse($node, $children, $coderef, $context);
        }
    }

    return;
}

###################################################################

1;

__END__

=head1 SEE ALSO

L<DBIx::Tree::MaterializedPath|DBIx::Tree::MaterializedPath>

L<DBIx::Tree::MaterializedPath::Node|DBIx::Tree::MaterializedPath::Node>

L<DBIx::Tree::MaterializedPath::PathMapper|DBIx::Tree::MaterializedPath::PathMapper>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-tree-materializedpath at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Tree-MaterializedPath>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Tree::MaterializedPath

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Tree-MaterializedPath>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Tree-MaterializedPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Tree-MaterializedPath>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Tree-MaterializedPath>

=back

=head1 AUTHOR

Larry Leszczynski, C<< <larryl at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Larry Leszczynski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

