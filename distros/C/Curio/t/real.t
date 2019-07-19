#!/usr/bin/env perl
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0 }
use strictures 2;
use Test2::V0;

use lib 't/lib';
use MyApp::Config;
use MyApp::Secrets;

is(
    myapp_config(),
    { foo=>3, bar=>'green' },
    'config retrieved successfully',
);

is(
    myapp_secret('baz'),
    54,
    'secret retrieved successfully',
);

is(
    myapp_secret('qux'),
    'yellow',
    'secret retrieved successfully',
);

done_testing;
