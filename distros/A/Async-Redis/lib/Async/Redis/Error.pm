package Async::Redis::Error;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.001';

use overload
    '""'     => 'stringify',
    bool     => sub { 1 },
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub message { shift->{message} }

sub stringify {
    my ($self) = @_;
    return $self->message // ref($self) . ' error';
}

sub throw {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;
    die $self;
}

1;

__END__

=head1 NAME

Async::Redis::Error - Base exception class for Redis errors

=head1 SYNOPSIS

    use Async::Redis::Error;

    # Create and throw
    Async::Redis::Error->throw(message => 'something went wrong');

    # Or create and die later
    my $error = Async::Redis::Error->new(message => 'oops');
    die $error;

    # Catch
    eval { ... };
    if ($@ && $@->isa('Async::Redis::Error')) {
        warn "Redis error: " . $@->message;
    }

=head1 DESCRIPTION

Base class for all Async::Redis exceptions. Subclasses provide
specific error types with additional context.

=cut
