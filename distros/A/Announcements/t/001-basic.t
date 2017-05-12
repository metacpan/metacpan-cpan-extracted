use Test::More;
use strict;
use warnings;

{
    package PushedButton;
    use Moose;

    package Button;
    use Moose;
    with 'Announcements::Announcing';

    sub push {
        my $self = shift;

        $self->announce(PushedButton->new);
    }
}

my $nuke = Button->new;

my ($inner_announcement, $inner_announcer, $inner_subscription);

my $subscription = Announcements::Subscription->new(
    criterion => 'PushedButton',
    action    => sub {
        ($inner_announcement, $inner_announcer, $inner_subscription) = @_;
        my $announcement = shift;

        isa_ok $announcement, 'PushedButton';
    },
);

$nuke->add_subscription($subscription);

$nuke->push;
is($inner_subscription, $subscription, 'same subscription object');
is($inner_announcer,    $nuke,         'same announcer object');

done_testing;

