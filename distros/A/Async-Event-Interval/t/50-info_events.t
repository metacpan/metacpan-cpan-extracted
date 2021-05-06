use strict;
use warnings;

use Async::Event::Interval;
use Data::Dumper;
use Test::More;

my $mod = 'Async::Event::Interval';

my $one = $mod->new(0, sub {});
my $two = $mod->new(0, sub {});

my $events = Async::Event::Interval::events();

is ref $events, 'HASH', 'Class events() returns a hash ref ok';

is keys %$events, 2, "Two events have been created ok";

for (keys %$events) {
    like $_, qr/^\d+$/, "Events key $_ is an integer ok";
    is ref $events->{$_}, 'HASH', "Event $_ is a hash ref ok";
    is keys %{ $events->{$_} }, 0, "After creation, event $_ hash is empty";
}

$one->start;
$two->start;

$events = Async::Event::Interval::events();

for (keys %$events) {
    like $_, qr/^\d+$/, "Events key $_ is still an integer ok";
    is ref $events->{$_}, 'HASH', "Event $_ is still a hash ref ok";
    is keys %{ $events->{$_} }, 1, "After creation, event $_ hash has a single key";
    like $events->{$_}{pid}, qr/^\d+$/, "Event $_ has pid key with a proper PID";
}

my $a = $one->shared_scalar;
my $b = $two->shared_scalar;
my $aa = $one->shared_scalar;
my $bb = $two->shared_scalar;

$events = Async::Event::Interval::events();

for (keys %$events) {
    like $_, qr/^\d+$/, "Events key $_ is still an integer ok";
    is ref $events->{$_}, 'HASH', "Event $_ is still a hash ref ok";
    is keys %{ $events->{$_} }, 2, "After creation, event $_ hash has a single key";
    like $events->{$_}{pid}, qr/^\d+$/, "Event $_ has pid key with a proper PID";
    is ref $events->{$_}{shared_scalars}, 'HASH', "Event $_ has shared_scalars href";
    is keys %{ $events->{$_}{shared_scalars} }, 2, "Event $_ has two shared scalars";

    for my $shared_key (keys %{ $events->{$_}{shared_scalars} }) {
        like $shared_key, qr/^[A-Z]{4}$/, "Shared scalar key $shared_key is an int ok";
        is ref $events->{$_}{shared_scalars}{$shared_key}, 'SCALAR', "Shared scalar $shared_key is a scalar ref";
        is ${ $events->{$_}{shared_scalars}{$shared_key} }, undef, "...and is undef";
    }
}

my $id = 0;

for ($one, $two) {
    is $_->info()->{pid}, $events->{$id}{pid}, "info() pid matches for event $id";

    for my $shared_key (keys %{$_->info->{shared_scalars}}) {
        like $shared_key, qr/^[A-Z]{4}$/, "Shared scalar key $shared_key is an int ok";
        is ref $_->info->{shared_scalars}{$shared_key}, 'SCALAR', "Shared scalar $shared_key is a scalar ref";
        is ${$_->info->{shared_scalars}{$shared_key}}, undef, "...and is undef";
    }

    my $actual_id = $_->id;

    is $actual_id, $id, "Event $actual_id has proper id()";

    $id++;
}

done_testing();
