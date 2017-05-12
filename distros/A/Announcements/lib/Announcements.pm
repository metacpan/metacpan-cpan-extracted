package Announcements;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Announcements - communicate across the object network

=head1 DESCRIPTION

This Announcements library implements a relatively simple extension
of the observer pattern for permitting the observers of an event to
communicate amongst eachother and with the publisher of the event. Many
implementations of the observer pattern use fixed strings as events, but
Announcements uses objects. Indeed, any object can be announced, and
each observer can call whichever methods on that object that it wishes.

=head1 EXAMPLE

The hello world of announcements is observing a value that changes. So
let's walk through such an implementation. You'll probably be adding
announcements to existing code only once you discover that you need the
observer pattern, so let's start with something whose values changes and
then add announcement logic to it.

    package NetHack::Character;
    use Moose;

    has x => (is => 'rw', isa => 'Num');
    has y => (is => 'rw', isa => 'Num');

    # teleport to a random spot on the map
    sub teleport {
        my $self = shift;
        my $new_x = rand();
        my $new_y = rand();
        $self->x($new_x);
        $self->y($new_y);
    }

=head2 Observation

Say we want to track whether the character has ever teleported. Because
teleportation can be used to escape from difficult fights, you could
have a special challenge for beating the game without teleporting. We
could implement this by changing the teleport function.

    sub teleport {
        my $self = shift;
        my $new_x = rand();
        my $new_y = rand();
        $self->x($new_x);
        $self->y($new_y);
        $self->has_ever_teleported(1);
    }

But instead let's write it as an announcement so that we can decouple
the teleportation logic from the conduct logic. The first step is to
declare an announcement class that represents the "we are about to
teleport" event.

    package NetHack::Announcement::Teleporting;
    use Moose;

    # that's all!

Then we can announce objects of this class in C<teleport>.

    sub teleport {
        my $self = shift;

        $self->announce('NetHack::Announcement::Teleporting');

        my $new_x = rand();
        my $new_y = rand();
        $self->x($new_x);
        $self->y($new_y);
    }

Finally we set up an observer that flips the C<has_ever_teleported> bit
upon teleport.

    $character->add_subscription(
        criterion => 'NetHack::Announcement::Teleporting',
        action    => sub {
            my ($announcement, $character) = @_;
            $character->has_ever_teleported(1);
        },
    );

=head2 Communication

Teleports always send you to a random spot on the map. But say you want
to implement an artifact that grants teleport control. If the character
is holding this artifact and is teleported, then the player can pick
the teleport's destination.

    package NetHack::Item::MasterKeyOfThievery;
    use Moose;
    with 'NetHack::Item::Artifact';

    sub 

Some levels in our game forbid teleportation for various reasons. Let's
say we want to implement that behavior as an announcement to avoid
polluting the character's teleport method with "are we on a level
that blocks teleportation?" logic.

    package NetHack::Announcement::Teleporting;
    use Moose;

    has current_x => (is => 'ro', isa => 'Num', required => 1);
    has current_y => (is => 'ro', isa => 'Num', required => 1);

    has new_x     => (is => 'rw', isa => 'Num', default => sub { rand() });
    has new_y     => (is => 'rw', isa => 'Num', default => sub { rand() });

This announcement class permits observers to select the destination
coordinates. If none of the observers select coordinates, then
random coordinates (like our original C<teleport> method) will be used.

Our observer in this case is a level, which forbids teleports. We can
implement this pretty easily by just setting the new coordinates to the
current coordinates.

    package NetHack::Level::Sokoban;
    use Moose;
    extends 'NetHack::Level';

    sub enter {
        my $self = shift;
        $self->subscribe('NetHack::Announcement::Teleporting' => sub {
            my $announcement = shift;

            # block the teleport
            $announcement->new_x($announcement->current_x);
            $announcement->new_y($announcement->current_y);
        });
    }

Now to make our C<teleport> method use this announcement.

    sub teleport {
        my $self = shift;

        my $announcement = NetHack::Announcement::Teleporting->new(
            current_x => $self->x,
            current_y => $self->y,
        );

        $self->announce($announcement);

        $self->x($announcement->new_x);
        $self->y($announcement->new_y);
    }

Now when we enter a Sokoban level, it will subscribe to the character's
teleporting announcements and block them by forcing them to teleport to
the same spot.

=head2 Ordering

The previous examples when taken together form a number of issues
related to ordering. This kind of problem crops up often when you have
very flexible systems.

teleport control -> block
conduct -> block

Alternatively in the general case, you can
subclass L<Announcements::Subscription> and
L<Announcements::SubscriptionRegistry> to add ordering logic to
the subscription sending. You could add a numeric priority to each
subscription, then in the registry push an announcement to each
subscription in priority order.

=head1 SEE ALSO

L<http://sartak.org/talks/yapc-na-2011/announcing-announcements/>

L<http://www.cincomsmalltalk.com/userblogs/vbykov/blogView?entry=3310034894>

L<http://www.cincomsmalltalk.com/userblogs/vbykov/blogView?searchCategory=Announcements%20Framework>

L<http://www.bofh.org.uk/2008/06/29/announcing-announcements-for-ruby>

L<https://github.com/pdcawley/announcements>

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2010-2011 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

