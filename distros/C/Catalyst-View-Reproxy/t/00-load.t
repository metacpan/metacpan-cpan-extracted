#!perl -T

use Test::More;

plan tests => 2;

use_ok('Catalyst::View::Reproxy', 'use Catalyst::View::Reproxy');
use_ok('Catalyst::Helper::View::Reproxy', 'use Catalyst::Helper::View::Reproxy');
