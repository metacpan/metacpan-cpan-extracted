package MyTest;

use strict;
use warnings;

use Test::More tests => 8;
use Test::Requires 'Dancer2::Plugin::Cache::CHI';
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';

use Cache;

my $mech = Test::WWW::Mechanize::PSGI->new( app => Dancer2->runner->psgi_app);

$mech->get_ok('/cached');
ok !$mech->content;

$mech->get_ok( '/font/Bocklin.ttf?t=fo' );

$mech->get_ok('/cached');
ok $mech->content;

$mech->get_ok('/fake');
$mech->get_ok( '/font/Bocklin.ttf?t=fo' );

is $mech->content => 'faked';
