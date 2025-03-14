package Config::Proxy::Node::Root;
use strict;
use warnings;
use parent 'Config::Proxy::Node::Section';
use Carp;

=head1 NAME

Config::Proxy::Node::Root - root node of proxy configuration parse tree

=head1 DESCRIPTION

Objects of this class represent the topmost node in proxy configuration tree.
Each parse tree contains exactly one object of this class. This node can be
reached from every node in the tree by following its B<parent> attribute
and is returned by the B<tree> method of B<Config::Proxy> class.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{dirty} = 0;
    return $self;
}

=head1 METHODS

This class inherits methods from L<Config::Proxy::Node::Section>, which
see.

=head2 is_root

Always true.

=cut

sub is_root { 1 }

=head2 is_dirty

    $bool = $node->is_dirty;

Returns true if the tree is C<dirty>, i.e. it was modified since it has been
created from the disk configuration file.

=cut

sub is_dirty {
    my $self = shift;
    return $self->{dirty}
}

=head2 mark_dirty

    $node->mark_dirty;

Sets the C<dirty> attribute.

=cut

sub mark_dirty {
    my $self = shift;
    $self->{dirty} = 1;
}

=head2 clear_dirty

    $node->clear_dirty;

Clears the C<dirty> attribute.

=cut

sub clear_dirty {
    my $self = shift;
    $self->{dirty} = 0;
}

=head1 SEE ALSO

L<Config::Proxy::Node>, L<Config::Proxy::Node::Section>.

=cut

1;

    
