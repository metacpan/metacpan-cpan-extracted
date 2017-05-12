#!/usr/bin/perl
use strict;
use warnings;

use Acme::Monkey::Frame;
use Acme::Monkey::Frame::Layer;
use Term::ReadKey;
use Term::ANSIColor qw( :constants );
use Time::HiRes qw( sleep );

my $frame = Acme::Monkey::Frame->new(
    width  => 30,
    height => 11,
);

my $background = Acme::Monkey::Frame::Layer->new(
    width  => $frame->width() * 20,
    height => $frame->height(),
);

foreach (1..int( ($background->width() * $background->height()) / 8 )) {
    my $x = (int( rand() * $background->width() ) * 2) + 1;
    my $y = int( rand() * $background->height() ) + 1;
    my $char = ($background->get($x, $y)) ? 'o' : '.';
    $background->set( $x, $y, $char );
}

$frame->layers->{z} = $background;

my $ship = Acme::Monkey::Frame::Layer->new(
    x => 2,
    y => 4,
    width  => 4,
    height => 3,
    color  => BOLD.CYAN,
);
$ship->set(
    1, 1,
    join("\n",
        "-\\",
        "=@>",
        "-/",
    )
);
$frame->layers->{a} = $ship;

my $enemy = Acme::Monkey::Frame::Layer->new(
    x => $frame->width()-3,
    y => int( $frame->height() / 2 ),
    width  => 2,
    height => 1,
    color  => BOLD.GREEN,
);
$enemy->set( 1, 1, '<=' );
$frame->layers->{b} = $enemy;

my $laser = Acme::Monkey::Frame::Layer->new(
    width  => 2,
    height => 1,
    hidden => 1,
    color  => BOLD.RED,
);
$laser->set( 1, 1, '--' );
$frame->layers->{c} = $laser;

my $boom = Acme::Monkey::Frame::Layer->new(
    width  => 6,
    height => 3,
    hidden => 1,
    color  => BOLD.RED.BLINK,
);
$boom->set( 1, 1, "\t\\\t\t/\n-BOOM-\n\t/\t\t\\" );
$frame->layers->{d} = $boom;

$frame->draw();

ReadMode 4;
eval {

foreach (1..1000) {
    my $key = ReadKey( -1 ) || '';

    last if ($key =~ /[xq]/);

    $ship->move_up() if ($key eq 'w');
    $ship->move_down() if ($key eq 's');
    $ship->move_left() if ($key eq 'a');
    $ship->move_right() if ($key eq 'd');

    if (rand() < .5) {
        $enemy->move_up() if ($enemy->y() > 1);
    }
    else {
        $enemy->move_down() if ($enemy->y() < $frame->height());
    }

    if ($key eq ' ') {
        if ($laser->hidden()) {
            $laser->hidden( 0 );
            $laser->x( $ship->x() );
            $laser->y( $ship->y() + 1 );
        }
    }

    if (!$laser->hidden()) {
        $laser->move_right( 2 );
        if ($laser->x() > $frame->width()) {
            $laser->hidden( 1 );
        }
        if ($laser->y() == $enemy->y() and $laser->x() >= $enemy->x()-1) {
            $laser->hidden( 1 );
            $enemy->hidden( 1 );
            $boom->y( $enemy->y() - 1 );
            $boom->x( $enemy->x() - 2 );
            $boom->hidden( 0 );
        }
    }

    $background->move_left();
    $frame->draw();

    if (!$boom->hidden()) {
        print "\n\nYOU WON!!!\n";
        last;
    }

    print "\nw = Up.  s = Down.  a = Left.  d = Right.\n<space> = Shoot.\nx = Exit.";

    sleep .2;
}

};
ReadMode 0;

__END__

=head1 NAME

monkey_ship.pl - Guide the intergallectic spaceship of the first confederate force of monkey citizens of the congo and brazillian rainforests.

=head1 DESCRIPTION

Using your masterful piloting skills guide the monkey-ship on 
a mission to destroy the giant <= ship.

