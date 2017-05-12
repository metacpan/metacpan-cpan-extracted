#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test to fix basic word syntaxe.

=cut

use Test::More tests => 13;

use_ok('App::WIoZ::Word');


my $w = App::WIoZ::Word->new( text => 'test', weight => 4 );
is($w->text,'test','text is test');
is($w->weight,4,'weight set to 4');
is($w->font->{font},'LiberationSans','default font to LiberationSans');
#is($w->angle,0,'most of the time angle is set to 0');


$w->height(10);
$w->width(40);

is($w->height,10,'basic test: real word height will be compute in graphic context');
is($w->width,40,'basic test: real word width will be compute in graphic context');

use_ok('App::WIoZ::Point');
my $pos = App::WIoZ::Point->new(x=>50,y=>60);
$w->update_c($pos);

is($w->c->x,50,'new position to x=50');
is($w->c->y,60,'new position to y=60');

is($w->p->x,30,'x for p is 30');
is($w->p->y,65,'y for p is 65');

is($w->p2->x,70,'x for p2 is 70');
is($w->p2->y,55,'y for p2 is 55');

