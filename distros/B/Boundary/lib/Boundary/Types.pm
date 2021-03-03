package Boundary::Types;
use strict;
use warnings;

use Type::Library -base,
    -declare => qw( ImplOf );

use Boundary ();

use Types::Standard -types;
use Class::Load qw(is_class_loaded);
use Scalar::Util qw(blessed);

__PACKAGE__->add_type({
    name   => 'ImplOf',
    parent => Object,
    constraint_generator => sub {
        my $self = $Type::Tiny::parameterize_type;
        my @interfaces = @_;

        my $display_name = $self->name_generator->($self, @interfaces);

        my %options = (
            constraint => sub {
                my ($target) = @_;
                my $impl = blessed($target);
                return if !$impl;
                return Boundary->check_implementations($impl, @interfaces);
            },
            display_name => $display_name,
            parameters   => [@interfaces],
            message => sub {
                my $impl = blessed($_);
                return "$_ is not blessed" if !$impl;
                return "$impl not loaded" if !is_class_loaded($impl); 
                return sprintf '%s did not pass type constraint "%s"', Type::Tiny::_dd($_), $display_name;
            },
        );

        return $self->create_child_type(%options);
    },
});

__PACKAGE__->meta->make_immutable;

1;
