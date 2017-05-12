package TestLog;
use Moose;
extends 'Catalyst::Log';

our $logged;

override warn => sub {
    my $self = shift;
    $logged = shift;
};

1;
