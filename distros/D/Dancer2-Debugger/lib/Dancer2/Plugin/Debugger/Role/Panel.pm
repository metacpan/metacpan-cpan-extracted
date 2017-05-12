package Dancer2::Plugin::Debugger::Role::Panel;

=head1 NAME

Dancer2::Plugin::Debugger::Role::Panel - base role for Dancer2 panels

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use Dancer2::Core::Types;
use Moo::Role;

=head1 ATTRIBUTES

=head2 plugin

An instance of L<Dancer2::Plugin::Debugger>.

=cut

has plugin => (
    is       => 'ro',
    isa      => InstanceOf ['Dancer2::Plugin::Debugger'],
    required => 1,
);

1;
