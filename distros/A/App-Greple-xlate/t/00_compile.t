use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::Greple::xlate
    App::Greple::xlate::null
    App::Greple::xlate::deepl
    App::Greple::xlate::gpty::gpt3
    App::Greple::xlate::gpty::gpt4
    App::Greple::xlate::gpty::gpt4o
    App::Greple::xlate::gpty::gpt5
    App::Greple::xlate::llm
    App::Greple::xlate::llm::gpt5
    App::Greple::xlate::Cache
    App::Greple::xlate::Mask
    App::Greple::xlate::Filter
);

done_testing;

