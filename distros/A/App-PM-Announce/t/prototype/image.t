#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use App::PM::Announce;

$ENV{APP_PM_ANNOUNCE_HOME} = 't/assets/home';

my $app = App::PM::Announce->new;

my $image = $app->feed->{meetup}->fetch_image( 'http://farm4.static.flickr.com/3243/2860445515_f3571f2149.jpg' );
is( -s $image, 122880 );
unlink $image or die $!
