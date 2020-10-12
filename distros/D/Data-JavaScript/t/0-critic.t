#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;
use Test2::Require::Perl 'v5.20';

use Test2::Tools::PerlCritic;

perl_critic_ok 'lib', 'test library files';
perl_critic_ok 't',   'test test files';

done_testing;
