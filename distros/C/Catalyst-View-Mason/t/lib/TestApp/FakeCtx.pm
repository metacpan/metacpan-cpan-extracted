package TestApp::FakeCtx;

use strict;
use warnings;
use TestApp::FakeLog;
use base qw/Catalyst/;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->log( TestApp::FakeLog->new([]) );

    return $self;
}

sub config {
    return {};
}

1;
