package Async::ResourcePool v0.1.3;

=head1 NAME

Async::ResourcePool - Resource pooling for asynchronous programs.

=head1 DESCRIPTION

This module implements the simple functionality of creating a source pool for
event-based/asynchronous programs.  It provides consumers with the ability to
have some code execute whenever a resource happens to be ready.  Further, it
allows resources to be categorized (by label) and limited as such.

=cut

use strict;
use warnings FATAL => "all";
use Carp qw( croak );

=head1 CONSTRUCTOR

=over 4

=item new [ ATTRIBUTES ]

=cut

sub new {
    my ($class, %params) = @_;

    my $self = bless {
        %params,

        _resources  => {},
        _allocated  => 0,
        _wait_queue => [],
        _available_queue  => [],
    }, $class;

    return $self;
}

=back

=head1 ATTRIBUTES

=over 4

=item factory -> CodeRef(POOL, CodeRef(RESOURCE, MESSAGE))

The factory for generating the resource.  The factory is a subroutine reference
which accepts an instance of this object and a callback as a reference.  The
callback, to be invoked when the resource has been allocated.

If no resource could be allocated due to error, then undef should be supplied
with the second argument being a string describing the failure.

=cut

sub factory {
    my ($self, $value) = @_;

    if (@_ == 2) {
        $self->{factory} = $value;
    }

    $self->{factory};
}

=item limit -> Int

The number of resources to create per label.

Optional.

=cut

sub limit {
    my ($self, $value) = @_;

    if (@_ == 2) {
        $self->{limit} = $value;
    }

    $self->{limit};
}

=item has_waiters -> Bool

A flag indicating whether or not this pool currently has a wait queue.

Read-only.

=cut

sub has_waiters {
    return scalar @{ shift->{_wait_queue} };
}

=item has_available_queue -> Bool

A flag indicating whether or not this pool has any idle resources available.

Read-only.

=cut

sub has_available {
    return scalar @{ shift->{_available_queue} };
}

=item size -> Int

The current size of the pool.

Read-only.

=cut

sub size {
    return shift->{_allocated};
}

=back

=head1 METHODS

=cut

sub _track_resource {
    my ($self, $resource) = @_;

    $self->{_resources}->{$resource} = $resource;
}

sub _is_tracked {
    my ($self, $resource) = @_;

    return exists $self->{_resources}{$resource};
}

sub _prevent_halt {
    my ($self) = @_;

    if ($self->has_waiters) {
        $self->lease(shift $self->{_wait_queue});
    }
}

=over 4

=item lease CALLBACK(RESOURCE, MESSAGE)

Request a lease, with a callback invoked when the resource becomes available.
The first argument of the callback will be the resource, if it was able to be
granted, the second argument of the callback will be the error message, which
will only be defined if first argument is not.

=cut

sub lease {
    my ($self, $callback) = @_;

    if ($self->has_available) {
        my $resource = shift $self->{_available_queue};

        delete $self->{_available}{$resource};

        $callback->($resource);
    }
    else {
        my $allocated = $self->size;

        unless ($allocated == $self->limit) {
            $self->{_allocated}++;

            $self->factory->(
                $self,
                sub {
                    my ($resource, $message) = @_;

                    if (defined $resource) {
                        $self->_track_resource($resource);
                    }
                    else {
                        # Decrement the semaphore so that we don't
                        # degrade the pool on an error state.
                        $self->{_allocated}--;

                        # Prevent halting by reentering the allocation
                        # routine if we have waiters, since we just
                        # lost a resource from the semaphore.
                        $self->_prevent_halt;
                    }

                    $callback->($resource, $message);
                }
            );
        }
        else {
            push $self->{_wait_queue}, $callback;
        }
    }
}

=item release RESOURCE

Return a resource to the pool.  This will signal any waiters which haven't yet
received a callback.

=cut

sub release {
    my ($self, $resource) = @_;

    # Ignore resources which are not tracked.
    # This may mean they've been invalidated.
    if ($self->{_resources}{$resource}) {
        unless ($self->{_available}{$resource}) {
            if ($self->has_waiters) {
                my $callback = shift $self->{_wait_queue};

                $callback->($resource);
            }
            else {
                $self->{_available}{$resource} = $resource;

                push $self->{_available_queue}, $resource;
            }
        }
        else {
            croak "Attempted to release resource twice: $resource";
        }
    }
    else {
        croak "Attempted to release untracked resource, $resource";
    }
}

=item invalidate RESOURCE

Invalidate a resource, signaling that it is no longer valid and no longer can
be distributed by this pool.  This will allocate another resource if there are
any waiters.

=cut

sub invalidate {
    my ($self, $resource) = @_;

    my $resources = $self->{_resources};
    my $available = $self->{_available_queue};

    $self->{_allocated}--;

    my $resource_name = "$resource";

    if (delete $resources->{$resource_name}) {
        # Strip the resource from the available queue so we don't accidently
        # dispatch it.
        @$available = grep $_ != $resource, @$available;

        delete $resources->{_available}{$resource_name};

        $self->_prevent_halt;
    }
}

=back

=cut

return __PACKAGE__;
