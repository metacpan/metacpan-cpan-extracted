package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;
use My::Module::Test::App;

use Astro::App::Satpass2::FormatTime;

klass( 'Astro::App::Satpass2::FormatTime' );

call_m( 'new', INSTANTIATE, 'Instantiate Astro::App::Satpass2::FormatTime' );

call_m( gmt => 1, TRUE, 'Turn on gmt' );

call_m( 'gmt', 1, 'Confirm gmt is on' );

call_m( format_datetime_width => '', 0, 'Width of null template' );

call_m( format_datetime_width => 'foo', 3,
    'Width of constant template' );

call_m( format_datetime_width => 'foo%%bar', 7,
    'Width of template with literal percent' );

done_testing;

1;

# ex: set textwidth=72 :
