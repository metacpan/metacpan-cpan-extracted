#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Catalyst::Test 'Foo';

is( get('/success'), 'base, success', 'Successful chain works');
is( get('/fail'), 'base', 'Die in base correctly stops chain');
is( get('/middle_fail'), 'base', 'Die in middle of chain works');

is( get('/base/success'), 'base_base, success', 'Base Successful chain works');
is( get('/base/fail'), 'base_base', 'Base Die in base correctly stops chain');
is( get('/base/middle_fail'), 'base_base', 'Base Die in middle of chain works');

is( get('/fail_ctx_error'), '1, base', 'ctx error preserved when die in Chain worked.');

my $res = request('/base/explicit_detach/endpoint');
is( $res->content, 'base_base, explicit_detach', 'explicit detach does not trigger error catching');
is( $res->header('X-DetachOnDie-Caught'), 0, 'exception not caught by action role');

my $res = request('/pitch_go');
is( $res->content, 'base, pitched, caught', 'Using ->go works');
is( $res->header('X-DetachOnDie-Caught'), 0, '... and rethrows the exception untouched');

done_testing();
