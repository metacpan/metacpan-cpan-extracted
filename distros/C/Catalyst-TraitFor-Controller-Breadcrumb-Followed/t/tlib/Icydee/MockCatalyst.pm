package Icydee::MockCatalyst;

use strict;
use warnings;

#
# This is only intended to Mock enough of the Catalyst calls to allow
# testing of the Catalyst::TraitFor::Controller::Breadcrumb::Followed package
#

sub new {
    my $class = shift;
    my $self = {};

    $self->{session}    = undef;
    $self->{config}     = undef;
    $self->{action}     = undef;
    $self->{req}        = Icydee::Request->new;
    bless($self, $class);
    return $self;
}

sub session {
    my ($self) = @_;

    return \%{$self->{session}};
}

sub config {
    my ($self) = @_;

    return \%{$self->{config}};
}

sub action {
    my ($self) = @_;

    return $self->{action};
}

# Not part of Catalyst, just to allow us to Mock the action
sub set_action {
    my ($self, $value) = @_;

    $self->{action} = $value;
}

sub uri_for {
    my ($self, $path) = @_;

    return $path;
}

sub req {
    my ($self) = @_;

    return $self->{req};
}

package Icydee::Request;

sub new {
    my $class = shift;
    my $self = {};

    $self->{arguments}  = [];
    bless($self, $class);
    return $self;
}

sub set_arguments {
    my ($self, @args) = @_;

    $self->{arguments} = \@args;
}

sub arguments {
    my ($self) = @_;

    return $self->{arguments};
}

1;
