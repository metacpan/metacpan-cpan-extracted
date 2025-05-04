use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::Greple::xlate
    App::Greple::xlate::null
    App::Greple::xlate::deepl
    App::Greple::xlate::gpt3
    App::Greple::xlate::gpt4
    App::Greple::xlate::gpt4o
    App::Greple::xlate::Cache
    App::Greple::xlate::Mask
    App::Greple::xlate::Filter
);

done_testing;

