package Database::Async::Backoff::Exponential;

use strict;
use warnings;

our $VERSION = '0.019'; # VERSION

use parent qw(Database::Async::Backoff);

use mro qw(c3);
use Future::AsyncAwait;
use List::Util qw(min);

Database::Async::Backoff->register(
    exponential => __PACKAGE__
);

sub new {
    my ($class, %args) = @_;
    return $class->next::method(
        max_delay => 30,
        initial_delay => 0.05,
        %args
    );
}

sub next {
    my ($self) = @_;
    return $self->{delay} ||= min(
        $self->max_delay,
        (2 * ($self->{delay} // 0))
         || $self->initial_delay
    );
}

1;
