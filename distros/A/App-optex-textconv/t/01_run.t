use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;

use lib '.';
use t::Util;

is(run()->status, 2, 'no arg');
is(run('--version')->status, 0, '--version');

is(run('-Mtextconv --version')->status, 0, '-Mtextconv --version');
is(run('-Mtextconv true')->status, 0, '-Mtextconv true');
is(run('-Mtextconv false')->status, 1, '-Mtextconv false');

done_testing;
