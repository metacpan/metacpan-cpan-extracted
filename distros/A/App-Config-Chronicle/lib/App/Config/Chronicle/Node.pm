package App::Config::Chronicle::Node;

use Moose;

our $VERSION = '0.07';    ## VERSION

=head1 NAME

App::Config::Chronicle::Node

=head1 DESCRIPTION

This module represents a node in app_config tree

=head1 ATTRIBUTES

=cut

=head2 name

short name of the node

=cut

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 parent_path

path in dot notation of the parent node.

=cut

has parent_path => (
    is  => 'ro',
    isa => 'Str',
);

=head2 path

path in dot notation of the current node.

=cut

has path => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_path {
    my $self = shift;
    return (($self->parent_path) ? $self->parent_path . '.' : '') . $self->name;
}

=head2 definition

definition of this node from definitions.yml

=cut

has 'definition' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'data_set' => (
    is       => 'ro',
    required => 1,
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
