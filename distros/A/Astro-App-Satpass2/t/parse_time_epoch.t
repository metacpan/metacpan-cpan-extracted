package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use Astro::App::Satpass2::ParseTime;

use lib qw{ inc };

use My::Module::Test::App;

klass( 'Astro::App::Satpass2::ParseTime' );

call_m( new => class => 'Astro::App::Satpass2::ParseTime::ISO8601',
    INSTANTIATE, 'Instantiate' );

my $now = time;

call_m( parse => "epoch $now", $now, qq<Parse of 'epoch $now' returns same> );

call_m( parse => \$now, $now, qq<Parse of \\'$now' returns same> );

done_testing;

1;

# ex: set textwidth=72 :
