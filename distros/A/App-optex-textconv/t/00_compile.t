use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::optex::textconv
    App::optex::textconv::Converter
    App::optex::textconv::default
    App::optex::textconv::msdoc
    App::optex::textconv::pandoc
    App::optex::textconv::pdf
    App::optex::textconv::tika
);

done_testing;

