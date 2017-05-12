package DBIx::Tree::MaterializedPath::PathMapper;

use warnings;
use strict;

use Carp;
use SQL::Abstract;

use Readonly;

Readonly::Scalar my $EMPTY_STRING => q{};

Readonly::Scalar my $DEFAULT_CHUNKSIZE => 5;
Readonly::Scalar my $MAX_CHUNKSIZE     => 8;

my $re_period = qr/[.]/msx;

=head1 NAME

DBIx::Tree::MaterializedPath::PathMapper - manipulates paths for "materialized path" trees

=head1 VERSION

Version 0.06

=cut

use version 0.74; our $VERSION = qv('0.06');

=head1 SYNOPSIS

    use DBIx::Tree::MaterializedPath::PathMapper;

    my $mapper = DBIx::Tree::MaterializedPath::PathMapper->new();

    # Path to the 2nd child of the 3rd child of the root node:
    my $path_in_db = $mapper->map('1.3.2');

    my $path = $mapper->unmap($path_in_db);    # "1.3.2"

=head1 DESCRIPTION

This module manipulates path representations for DBIx::Tree::MaterializedPath
"materialized path" trees.

=head2 PATH REPRESENTATIONS

The "human-readable" path is a sequence of integers separated by
periods that represents the path from the root node of the tree
to one of it's children.

The first integer (representing the root node) is always a "1".
Subsequent integers represent the Nth child node of the parent,
e.g. "1.7" would be the 7th child of the root node, and "1.7.2"
would be the 2nd child of the 7th child of the root node.

The "human-readable" path for each node is the tree is mapped
into a different format for storage in the database.  The format
used for database storage must meet several criteria in order for
tree manipulation via SQL to work:

=over 4

=item *

The human-readable path must map uniquely to the stored path,
and vice versa.

=item *

The stored path strings should sort such that the nodes they
represent would be traversed leftmost depth-first.

=item *

The length of each "chunk" of the stored path (where each chunk
represents one step deeper into the tree) should be a fixed value.
E.g. "1.108.15" could map to something like "001.108.015" if the
chunksize was 3. This ensures that the length of the path
representation is a function of the depth of the node in the tree.

=item *

The stored path may be prefixed with additional info, but there
should be no extraneous info at the end.  Removing one "chunk"
from the end of a node's path should always result in the path
for that node's parent.

=back

=head2 LIMITATIONS

This implementation uses a default chunksize of 5 when mapping
the digits in the human-readable path into a hex representation.
This means that the highest numbered child at any level is
0xfffff, or 1,048,575.

In addition to limiting the maximum children a node may have,
the chunksize also affects the length of the path strings and
thus the amount of database storage required.

The default chunksize may be overridden by passing a "chunksize"
option to C<new>, with an integer value ranging from 1 to 8.

=head1 METHODS

=head2 new

    $mapper = DBIx::Tree::MaterializedPath::PathMapper->new()

Returns a path mapping object.

=cut

sub new
{
    my ($class, @args) = @_;

    my $options = ref $args[0] eq 'HASH' ? $args[0] : {@args};

    my $self = bless {}, ref($class) || $class;
    $self->_init($options);
    return $self;
}

sub _init
{
    my ($self, $options) = @_;

    $self->{_version} = '1';    # must be single character

    # Size of storage format path chunks:
    $self->{_chunksize} = $options->{chunksize} || $DEFAULT_CHUNKSIZE;
    $self->{_chunksize} = $MAX_CHUNKSIZE
      if $self->{_chunksize} > $MAX_CHUNKSIZE;

    $self->{_sqlmaker} = SQL::Abstract->new();

    $self->{_cache} = {};

    return;
}

#
# Be sure to keep _parse_path() consistent with map()...
#
sub _parse_path
{
    my ($self, $path) = @_;
    my $extra     = substr($path, 0, 1);
    my $chunksize = substr($path, 1, 1);
    my $pathpart  = substr($path, 2);
    return ($chunksize, $pathpart, $extra);
}

=head2 is_root

    $mapper->is_root( $path )

Given a path, returns true if the path represents the root node.

=cut

# Be sure to keep is_root() consistent with map()...

sub is_root
{
    my ($self, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);
    return $self->_is_root($chunksize, $pathpart) ? 1 : 0;
}

sub _is_root
{
    my ($self, $chunksize, $pathpart) = @_;
    return 0 unless $chunksize;
    return (length($pathpart) == $chunksize) ? 1 : 0;
}

=head2 depth

    $mapper->depth( $path )

Given a path, returns the depth of the node in the tree.
The root node is at zero depth.

=cut

sub depth
{
    my ($self, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);
    return int(length($pathpart) / $chunksize) - 1;
}

=head2 map

    $mapper->map( $human_readable_path )

Maps a string representing the path from the root node of the tree
to a child node from human-readable format (e.g. "1.2.4.1") to the
format stored in the database.

=cut

sub map    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
    my ($self, $hrpath) = @_;

    my $chunksize = $self->{_chunksize};
    my $format    = '%0' . $chunksize . 'x';

    my $pathpart = join $EMPTY_STRING,
      map { sprintf($format, $_) } split($re_period, $hrpath);

    return $self->_map($chunksize, $pathpart);
}

sub _map
{
    my ($self, $chunksize, $pathpart) = @_;
    my $path = $self->{_version} . $chunksize . $pathpart;
    return $path;
}

#
# Be sure to keep _map_chunk() consisent with map()...
#
sub _map_chunk
{
    my ($self, $chunk, $chunksize) = @_;
    $chunksize ||= $self->{_chunksize};
    my $format = '%0' . $chunksize . 'x';
    return sprintf($format, $chunk);
}

=head2 unmap

    $mapper->unmap( $path )

Maps a string representing the path from the root node of the tree
to a child node from the format stored in the database to
human-readable format (e.g. "1.2.4.1").

=cut

sub unmap
{
    my ($self,      $path)     = @_;
    my ($chunksize, $pathpart) = $self->_parse_path($path);

    # This doesn't work in perl 5.6.1, the parentheses
    # for grouping and repeating are not allowed:
    #
    #my $format = "(A$chunksize)*";

    # Build an explicit format that works in Perl 5.6.1:
    my $num_chunks = int(length($pathpart) / $chunksize);
    my $format     = "A$chunksize" x $num_chunks;

    my $hrpath = join q{.}, map { hex $_ } unpack($format, $pathpart);
    return $hrpath;
}

#
# Be sure to keep _unmap_chunk() consistent with unmap()...
#
sub _unmap_chunk
{
    my ($self, $chunk) = @_;
    return hex($chunk);
}

=head2 parent_path

    $mapper->parent_path( $path )

Given a path to a node, return the path to its immediate parent.

Returns an empty string if the input path represents the root node.

=cut

sub parent_path
{
    my ($self, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);

    return $EMPTY_STRING if $self->_is_root($chunksize, $pathpart);

    my $parentpathpart = substr($pathpart, 0, -$chunksize);

    return $self->_map($chunksize, $parentpathpart);
}

=head2 first_child_path

    $mapper->first_child_path( $path )

Given a path to a node, return a path to the first child
of that node.

=cut

sub first_child_path
{
    my ($self, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);

    return $path . $self->_map_chunk(1, $chunksize);
}

=head2 next_child_path

    $mapper->next_child_path( $path, $optional_n )

Given a path to a child node, return a path to the next child
for the same parent.

If I<$n> is specified, return the path to the nth next child.
(I<$n> effectively defaults to 1.)

Returns an empty string if the input path represents the root node.

=cut

sub next_child_path
{
    my ($self, $path, $n) = @_;
    $n ||= 1;

    my ($chunksize, $pathpart) = $self->_parse_path($path);

    return $EMPTY_STRING if $self->_is_root($chunksize, $pathpart);

    my $last_chunk = substr($path, -$chunksize);
    $last_chunk = $self->_unmap_chunk($last_chunk);
    $last_chunk += $n;
    $last_chunk = $self->_map_chunk($last_chunk, $chunksize);
    substr($path, -$chunksize) = $last_chunk;

    return $path;
}

=head2 where

    $mapper->where( $where )

Given an L<SQL::Abstract|SQL::Abstract>-styleSQL "where"
data structure, return an SQL "where" clause,
and the corresponding array of bind params.

=cut

sub where
{
    my ($self, $where) = @_;

    my $sqlmaker = $self->{_sqlmaker};
    my ($sql, @bind_params) = $sqlmaker->where($where);
    return ($sql, @bind_params);
}

=head2 child_where

    $mapper->child_where( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an SQL "where" clause suitable for finding the node's
direct children, and the corresponding array of bind params.

=cut

sub child_where
{
    my ($self, $path_col, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);

    my $like = $path . ('_' x $chunksize);

    my $sqlmaker = $self->{_sqlmaker};
    my ($sql, @bind_params) = $sqlmaker->where({$path_col => {-like => $like}});
    return ($sql, @bind_params);
}

=head2 sibling_where

    $mapper->sibling_where( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an SQL "where" clause suitable for finding the node's
siblings, and the corresponding array of bind params.

=cut

sub sibling_where
{
    my ($self, $path_col, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);

    my $like = $path;
    substr($like, -$chunksize) = '_' x $chunksize;

    my $sqlmaker = $self->{_sqlmaker};
    my ($sql, @bind_params) = $sqlmaker->where({$path_col => {-like => $like}});
    return ($sql, @bind_params);
}

=head2 sibling_to_the_right_where

    $mapper->sibling_to_the_right_where( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an SQL "where" clause suitable for finding siblings
to the right of the node, and the corresponding array of bind
params.

=cut

sub sibling_to_the_right_where
{
    my ($self, $path_col, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);

    my $like = $path;
    substr($like, -$chunksize) = '_' x $chunksize;

    my $sqlmaker = $self->{_sqlmaker};
    my ($sql, @bind_params) = $sqlmaker->where(
                     {$path_col => [-and => {-like => $like}, {'>' => $path}]});
    return ($sql, @bind_params);
}

=head2 sibling_to_the_left_where

    $mapper->sibling_to_the_left_where( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an SQL "where" clause suitable for finding siblings
to the left of the node, and the corresponding array of bind
params.

=cut

sub sibling_to_the_left_where
{
    my ($self, $path_col, $path) = @_;

    my ($chunksize, $pathpart) = $self->_parse_path($path);

    my $like = $path;
    substr($like, -$chunksize) = '_' x $chunksize;

    my $sqlmaker = $self->{_sqlmaker};
    my ($sql, @bind_params) = $sqlmaker->where(
                     {$path_col => [-and => {-like => $like}, {'<' => $path}]});
    return ($sql, @bind_params);
}

=head2 descendants_where_struct

    $mapper->descendants_where_struct( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an L<SQL::Abstract|SQL::Abstract>-styleSQL "where"
data structure suitable for finding all of
the node's descendants.

=cut

sub descendants_where_struct
{
    my ($self, $path_col, $path) = @_;

    my $cache = $self->{_cache};
    my $key   = 'descendants_where_struct';

    unless ($cache->{$key}->{$path_col}->{$path})
    {
        my $like = $path . q{%};

        $cache->{$key}->{$path_col}->{$path} =
          {$path_col => [-and => {-like => $like}, {q{!=} => $path}]};
    }

    return $cache->{$key}->{$path_col}->{$path};
}

=head2 descendants_where

    $mapper->descendants_where( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an SQL "where" clause suitable for finding all of
the node's descendants, and the corresponding array of
bind params.

=cut

sub descendants_where
{
    my ($self, $path_col, $path) = @_;

    my $cache = $self->{_cache};
    my $key   = 'descendants_where';

    unless ($cache->{$key}->{$path_col}->{$path})
    {
        my $where = $self->descendants_where_struct($path_col, $path);

        my $sqlmaker = $self->{_sqlmaker};
        my ($sql, @bind_params) = $sqlmaker->where($where);
        $cache->{$key}->{$path_col}->{$path} = {
                                                sql         => $sql,
                                                bind_params => \@bind_params,
                                               };
    }

    my $data = $cache->{$key}->{$path_col}->{$path};
    return ($data->{sql}, @{$data->{bind_params}});
}

=head2 descendants_and_self_where

    $mapper->descendants_and_self_where( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an SQL "where" clause suitable for finding a node and
all of its descendants, and the corresponding array of
bind params.

=cut

sub descendants_and_self_where
{
    my ($self, $path_col, $path) = @_;

    my $like = $path . q{%};

    my $sqlmaker = $self->{_sqlmaker};
    my ($sql, @bind_params) = $sqlmaker->where({$path_col => {-like => $like}});
    return ($sql, @bind_params);
}

=head2 parent_where

    $mapper->parent_where( $path_column_name, $path )

Given the name of the path column and a path to a node,
return an SQL "where" clause suitable for finding the node's
parent, and the corresponding array of bind params.

=cut

sub parent_where
{
    my ($self, $path_col, $path) = @_;

    my ($sql, @bind_params) = (undef, undef);

    my $parent_path = $self->parent_path($path);
    if ($parent_path)
    {
        my $sqlmaker = $self->{_sqlmaker};
        ($sql, @bind_params) = $sqlmaker->where({$path_col => $parent_path});
    }
    return ($sql, @bind_params);
}

=head2 is_ancestor_of

    $mapper->is_ancestor_of( $path1, $path2 )

Return true if I<path1> represents an ancestor of I<path2>.

Returns false if I<path1> and I<path2> represent the same node.

=cut

sub is_ancestor_of
{
    my ($self, $path1, $path2) = @_;

    croak 'Missing path' unless $path1 && $path2;

    return 0 if $path1 eq $path2;
    return (substr($path2, 0, length($path1)) eq $path1) ? 1 : 0;
}

=head2 is_descendant_of

    $mapper->is_descendant_of( $path1, $path2 )

Return true if I<path1> represents a descendant of I<path2>.

Returns false if I<path1> and I<path2> represent the same node.

=cut

sub is_descendant_of
{
    my ($self, $path1, $path2) = @_;

    croak 'Missing path' unless $path1 && $path2;

    return 0 if $path1 eq $path2;
    return (substr($path1, 0, length($path2)) eq $path2) ? 1 : 0;
}

1;

__END__

=head1 SEE ALSO

L<DBIx::Tree::MaterializedPath|DBIx::Tree::MaterializedPath>

L<DBIx::Tree::MaterializedPath::Node|DBIx::Tree::MaterializedPath::Node>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-tree-materializedpath at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Tree-MaterializedPath>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Tree::MaterializedPath::PathMapper

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

