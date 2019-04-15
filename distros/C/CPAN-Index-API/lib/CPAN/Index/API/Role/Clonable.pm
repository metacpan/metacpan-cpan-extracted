package CPAN::Index::API::Role::Clonable;

our $VERSION = '0.008';

use strict;
use warnings;

use Moose::Role;

sub clone
{
    my ($self, %params) = @_;
    $self->meta->clone_object($self, %params);
}

=pod

=encoding UTF-8

=head1 NAME

CPAN::Index::Role::Clonable - Clones index file objects

=head1 PROVIDES

=head2 clone

Clones the object. Parameters can be supplied as key/value pairs to override
the values of existing attributes.

=cut

1;
