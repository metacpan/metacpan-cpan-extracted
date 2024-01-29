#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Data::Turtle';

my $t = new_ok 'Data::Turtle';

my @x = $t->get_state;
is_deeply \@x, [250,250,270,1,'black',1], 'get_state';

$t->forward(10);

@x = $t->position;
is_deeply \@x, [250,240], 'forward x,y';

$t->backward(10);
@x = $t->position;
is_deeply \@x, [250,250], 'backward x,y';

@x = $t->goto(10,10);
is_deeply \@x, [250,250,10,10,'black',1], 'goto';

$t->home;

@x = $t->get_state;
is_deeply \@x, [250,250,270,1,'black',1], 'get_state';

$t->pen_up;
cmp_ok $t->pen_status, '==', 0, 'pen_up';

$t->pen_down;
cmp_ok $t->pen_status, '==', 1, 'pen_down';

$t->right(45);
cmp_ok $t->heading, '==', 315, 'right';

$t->right(1);
cmp_ok $t->heading, '==', 316, 'right';

$t->left(1);
cmp_ok $t->heading, '==', 315, 'left';

@x = $t->position;
is_deeply \@x, [250,250], 'position x,y';

$t->mirror;
cmp_ok $t->heading, '==', -315, 'mirror';

$t->set_state( 10, 10, 10, 0, 'red', 10 );

@x = $t->get_state;
is_deeply \@x, [10,10,10,0,'red',10], 'get_state';

done_testing();
