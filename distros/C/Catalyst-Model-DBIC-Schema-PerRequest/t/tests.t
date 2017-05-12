#!/usr/bin/env perl

use lib::abs './lib';

use warnings;
use strict;

use Test::More;
use Test::Exception;

use Catalyst::Test 'TestApp';

is(TestApp->model('DB')->schema->test_attr, 'DB', 'ok');
is(get('/'), 'DBPerRequest', 'Got DBPerRequest response.');
ok(get('/model_result'), 'Got DBPerRequest resultset via model.');


throws_ok { TestApp->model('DBPerRequest') } qr/is a per-request only model/,
    'throws is a per-request only model error';

done_testing;
