package TestApp::FakeLog;

use strict;
use warnings;
use MRO::Compat;
use base qw/Catalyst::Log/;

sub new {
    my ($self, $warnings_ref, @args) = @_;

    $self = $self->next::method(@args);
    $self->{_warnings_ref} = $warnings_ref;

    return $self;
}

sub warn {
    my ($self, $msg) = @_;
    push @{ $self->{_warnings_ref} }, $msg;
}

*debug = *info = *error = *fatal = *is_debug = sub { 1 };

1;
