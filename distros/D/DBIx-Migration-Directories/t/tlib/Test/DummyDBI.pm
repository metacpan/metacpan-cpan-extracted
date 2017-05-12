#!perl

package Test::DummyDBI;

use strict;
use warnings;

return 1;

sub new {
    my $class = shift;
    return bless { Driver => { Name => 'dummy' }, rv => 1, @_ }, $class;
}

sub good_rv {
    my $self = shift;
    $self->{rv} = 1;
}

sub bad_rv {
    my $self = shift;
    $self->{rv} = undef;
}

sub prepare {
    my $self = shift;
    return $self;
}

sub do {
    my $self = shift;
    return $self->{rv};
}

sub execute {
    my $self = shift;
    return $self->{rv};
}

sub fetchrow_arrayref {
    return;
}

sub commit {
    my $self = shift;
    return $self->{rv};
}

sub rollback {
    my $self = shift;
    return $self->{rv};
}

sub begin_work {
    my $self = shift;
    return $self->{rv};
}

sub finish {
    my $self = shift;
    return $self->{rv};
}

sub quote {
    my($self, $str) = @_;
    return $str;
}

sub selectrow_array {
    my $self = shift;
    return $self->{rv};
}

sub transaction_error {
    my $self = shift;
    return $self->{rv};
}

sub err { return; }

sub errstr { return; }

sub state { return; }

sub set_err { return; }

sub transaction { my($self, $sub) = @_; return $sub->(); }
