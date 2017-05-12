#!perl

use strict;
use warnings;
use lib 't/lib';

use Test::More;

use_ok('CatalystX::PSGIApp');

is( CatalystX::PSGIApp->psgi_app('t::lib::Support::has_method')->(), 'psgi_app()',
    "Uses psgi_app() when available" );
is( CatalystX::PSGIApp->psgi_app('t::lib::Support::does_not_have_method')->(),
    'PSGI', 'Sets up PSGI engine when necessary' );

done_testing();
