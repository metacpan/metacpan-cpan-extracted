#!/usr/bin/perl
use strict;
use warnings;

use Acme::Monkey::Frame;
use Acme::Monkey::Frame::Layer;
use Term::ANSIColor qw( :constants );
use Time::HiRes qw( sleep );
use Term::ReadKey;

my $frame = Acme::Monkey::Frame->new(
    width  => 20,
    height => 10,
);

my $background = Acme::Monkey::Frame::Layer->new(
    width  => $frame->width(),
    height => $frame->height(),
    color  => GREEN,
);

foreach my $x (1..$background->width()) {
foreach my $y (1..$background->height()) {
    my $folliage = int( rand() * 12) -6;
    if ($folliage < 3) {
        $background->set( $x, $y, '.' );
    }
    elsif ($folliage==3) {
        $background->set( $x, $y, '%' );
    }
    elsif ($folliage==4) {
        $background->set( $x, $y, 'X' );
    }
    else {
        $background->set( $x, $y, '+' );
    }
}
}

$frame->layers->{z} = $background;

my $food = Acme::Monkey::Frame::Layer->new(
    width  => $frame->width(),
    height => $frame->height(),
    color  => BOLD.YELLOW,
);
$frame->layers->{x} = $food;

my %monkeys;
my $monkey_id = 1;

sub create_monkey {
    my ($x, $y, $age) = @_;

    my $layer = Acme::Monkey::Frame::Layer->new(
        width  => 1,
        height => 1,
        x => $x,
        y => $y,
        color  => RED,
    );
    $age = 1;
#    $age ||= int(rand() * 100) + 1;
    $layer->set( 1, 1, age_char($age) );

    $frame->layers->{"monkey_$monkey_id"} = $layer;

    $monkeys{$monkey_id} = {
        layer  => $layer,
#        hunger => int(rand() * 20) + 1,
        hunger => 0,
        age    => $age,
        last_move => 0,
    };

    $monkey_id ++;
}

sub age_char {
    my ($age) = @_;

    return '.' if ($age < 7);
    return 'o' if ($age < 20);
    return '@' if ($age < 80);
    return '#';
}

sub add_food {
    $food->set(
        int(rand() * $frame->width()) + 1,
        int(rand() * $frame->height()) + 1,
        '/',
    );
}

ReadMode 4;
eval {

foreach (1..1000) {
    my $key = ReadKey( -1 ) || '';

    last if ($key =~ /[xq]/);

    if ($key eq 'c') {
        create_monkey(
            int(rand() * $frame->width()) + 1,
            int(rand() * $frame->height()) + 1,
        );
    }
    elsif ($key eq 'f') {
        add_food();
        add_food();
        add_food();
    }

    my $monkey_at = [];
    my $baby_had  = [];

    foreach my $id (keys %monkeys) {
        my $monkey = $monkeys{ $id };
        my $layer = $monkey->{layer};

        $monkey->{age} ++;
        if ($monkey->{age} > 100) {
            delete $frame->layers->{"monkey_$id"};
            delete $monkeys{ $id };
            next;
        }
        $layer->set( 1, 1, age_char($monkey->{age}) );

        $monkey->{hunger}++;
        if ($monkey->{hunger} > 40) {
            delete $frame->layers->{"monkey_$id"};
            delete $monkeys{ $id };
            next;
        }

        my $x = $layer->x();
        my $y = $layer->y();

        if ($food->get($x, $y)) {
            $monkey->{hunger} -= 3;
            $monkey->{hunger} = 0 if ($monkey->{hunger} < 0);
            $food->set($x, $y, "\t")
        }

        if ($monkey->{age} > 14 and $monkey->{age} < 50) {
        if ($monkey_at->[ $x ]->[ $y ]) {
            if (!$baby_had->[ $x ]->[ $y ]) {
                if ($monkey->{hunger}<30) {
                    create_monkey( $x, $y, 1 );
                    $baby_had->[ $x ]->[ $y ] = 1;
                    $monkey->{hunger} += 8;
                }
            }
        }
        }
        if ($monkey->{hunger}<15) {
            $monkey_at->[ $x ]->[ $y ] = 1;
        }

        my $move = int( rand() * 4 ) + 1;
        if ($monkey->{hunger} > 15) {
            $move=1 if ($food->get($x, $y-1));
            $move=2 if ($food->get($x, $y+1));
            $move=3 if ($food->get($x-1, $y));
            $move=4 if ($food->get($x+1, $y));
        }
        else {
            $move=1 if ($monkey_at->[$x]->[$y-1]);
            $move=2 if ($monkey_at->[$x]->[$y+1]);
            $move=3 if ($monkey_at->[$x-1]->[$y]);
            $move=4 if ($monkey_at->[$x+1]->[$y]);
        }

        if ($move==1) {
            next if ($monkey->{last_move} == 2);
            $layer->move_up() if ($y > 1);
        }
        elsif ($move==2) {
            next if ($monkey->{last_move} == 1);
            $layer->move_down() if ($y < $frame->height());
        }
        elsif ($move==3) {
            next if ($monkey->{last_move} == 4);
            $layer->move_left() if ($x > 1);
        }
        elsif ($move==4) {
            next if ($monkey->{last_move} == 3);
            $layer->move_right() if ($x < $frame->width());
        }

        $monkey->{last_move} = $move;
    }

    add_food();

    $frame->draw();

    print "\nc = Create new monkey baby.\nf = Create some bannanas to eat.\nx = Exit.";

    sleep 1;
}

};
ReadMode 0;

__END__

=head1 NAME

monkey_life.pl - Be a monkey god.

=head1 SYNOPSIS

  monkey_life.pl

=head1 DESCRIPTION

When you first start this script you will be shown a top down view of
a lush rainforest.   In it will be the occasional bannana.

It is silent and eerie until the creator (you) decides to start life.

Make sure you feed your little primates, for they will die fast without
food and will not mate unless they are well fed.

