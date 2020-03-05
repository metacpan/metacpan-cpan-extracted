#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Spinner;

my $root = mk_window;

my $win = $root->make_sub( 2, 2, 5, 20 );

my $spinner = Tickit::Widget::Spinner->new;

ok( defined $spinner, 'defined $spinner' );

$spinner->set_window( $win );

flush_tickit;

is_display( [ BLANKLINES(4),
              [BLANK(11), TEXT("\\")]],
            'Display initially' );

# TODO: Can't unit-test any more for now because we don't have timer support
# in Tickit::Test.

done_testing;
