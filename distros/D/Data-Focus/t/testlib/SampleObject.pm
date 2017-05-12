package testlib::SampleObject;
use strict;
use warnings;

sub new {
    return bless {}, shift;
}

sub set {
    my ($self, $key, $val) = @_;
    $self->{$key} = $val;
}

sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

1;
