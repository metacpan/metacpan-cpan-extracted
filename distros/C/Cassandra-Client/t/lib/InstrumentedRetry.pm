package InstrumentedRetry;
use 5.010;
use strict;
use warnings;

sub new {
    my ($class, $retry_policy)= @_;
    return bless {
        retry_policy => $retry_policy,
        counters => {}
    }, $class;
}

sub reset {
    my ($self) = @_;
    $self->{counters}= {};
}

sub on_read_timeout {
    my ($self, @args) = @_;
    $self->{counters}{on_read_timeout} +=1 ;
    $self->{retry_policy}->on_read_timeout(@args);
}

sub on_unavailable {
    my ($self, @args) = @_;
    $self->{counters}{on_unavailable} +=1 ;
    $self->{retry_policy}->on_unavailable(@args);
}

sub on_write_timeout {
    my ($self, @args) = @_;
    $self->{counters}{on_write_timeout} +=1 ;
    $self->{retry_policy}->on_write_timeout(@args);
}

sub on_request_error {
    my ($self, @args) = @_;
    $self->{counters}{on_request_error} +=1 ;
    $self->{retry_policy}->on_request_error(@args);
}

1;
