package Test::AQWrapper;
use strict;
use warnings;
use base qw(Async::Queue);
use Test::More;
use Test::Builder;

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{__finish_num} = 0;
    $self->{__push_num} = 0;
    return $self;
}

sub push {
    my ($self, @args) = @_;
    $self->{__push_num}++;
    return $self->SUPER::push(@args);
}

sub finish {
    my ($self) = @_;
    $self->{__finish_num}++;
}

sub clearCounter {
    my ($self) = @_;
    $self->{__push_num} = $self->{__finish_num} = 0;
}

sub check {
    my ($self, $exp_length, $exp_running, $exp_finish, $exp_pushed) = @_;
    local $Test::Builder::Level += 1;
    is($self->length, $exp_length, "length is $exp_length") if defined $exp_length;
    is($self->waiting, $self->length, "waiting is the same as length");
    is($self->running, $exp_running, "running is $exp_running") if defined $exp_running;
    is($self->{__finish_num}, $exp_finish, "finish num is $exp_finish") if defined $exp_finish;
    if($self->concurrency > 0) {
        cmp_ok($self->running, "<=", $self->concurrency, "running <= concurrency") or
            diag("running: " . $self->running . ", concurrency: " . $self->concurrency);
    }
    $exp_length = $self->length if not defined $exp_length;
    $exp_running = $self->running if not defined $exp_running;
    $exp_finish = $self->{__finish_num} if not defined $exp_finish;
    $exp_pushed = $exp_length + $exp_running + $exp_finish if not defined $exp_pushed;
    is($self->{__push_num}, $exp_pushed, "pushed num is $exp_pushed");
}

1;
