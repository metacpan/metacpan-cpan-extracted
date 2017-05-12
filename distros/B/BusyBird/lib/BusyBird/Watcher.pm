package BusyBird::Watcher;
use v5.8.0;
use strict;
use warnings;

1;

=pod

=head1 NAME

BusyBird::Watcher - interface for watcher objects

=for test_synopsis
my ($timeline); sub callback {}

=head1 SYNOPSIS

    my $watcher = $timeline->watch_unacked_counts(
        assumed => { total => 0 },
        callback => sub { ... }
    );
    
    $watcher->active;   ## returns true if the $watcher is active
    $watcher->cancel(); ## cancels the $watcher

=head1 DESCRIPTION

This is an interface (or role) class for watcher objects.
A watcher is something that represents a callback registered somewhere.
Users can use a watcher to cancel (i.e. unregister) the callback.

L<BusyBird::Watcher> does not implement any method.
Implementations of L<BusyBird::Watcher> must be a subclass of L<BusyBird::Watcher>
and implement the following methods.

=head1 OBJECT METHODS

=head2 $is_active = $watcher->active()

Returns true if the C<$watcher> is active. Returns false otherwise.

An active watcher is the one whose callback can be called.
On the other hand, the callback of an inactive watcher will never be called.

=head2 $watcher->cancel()

Cancels the C<$watcher>, that is, makes it inactive.

If C<$watcher> is already inactive, it stays inactive.


=head1 AUTHOR

Toshio Ito C<< <toshioito [at] cpan.org> >>

=cut

