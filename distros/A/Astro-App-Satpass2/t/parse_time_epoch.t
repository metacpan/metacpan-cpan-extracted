package main;

use 5.008;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;	# Because of done_testing();
use My::Module::Test::App;

require_ok 'Astro::App::Satpass2::ParseTime';

class 'Astro::App::Satpass2::ParseTime';

method new => class => 'Astro::App::Satpass2::ParseTime::ISO8601',
    INSTANTIATE, 'Instantiate';

my $now = time;

method parse => "epoch $now", $now, qq<Parse of 'epoch $now' returns same>;

method parse => \$now, $now, qq<Parse of \\'$now' returns same>;

done_testing;

1;

# ex: set textwidth=72 :
