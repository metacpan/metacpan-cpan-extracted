
use strict;
use warnings;

use Test::More tests => 4;
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';

use Basic;

my $mech = Test::WWW::Mechanize::PSGI->new( app => Dancer2->runner->psgi_app);

$mech->get_ok( '/font/Bocklin.ttf' );

my $size = length $mech->content;
is $size  => -s 't/lib/fonts/Bocklin.ttf', 'original size';

$mech->get_ok( '/font/Bocklin.ttf?t=fo' );

cmp_ok length( $mech->content ), '<', $size, 'subset smaller than whole set';
