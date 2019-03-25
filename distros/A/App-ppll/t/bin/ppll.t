#!/usr/bin/env perl

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use English qw( -no_match_vars );
use Test::Most;

## no critic [InputOutput::ProhibitBacktickOperators]

require_ok 'App::ppll';

qx(
bin/ppll true </dev/null >/dev/null 2>&1
);
is $CHILD_ERROR, 0, 'true';

qx(
bin/ppll -c 'echo \$1' a b c </dev/null >/dev/null 2>&1
);
is $CHILD_ERROR, 0, '-c echo';

qx(
bin/ppll echo <<EOF >/dev/null 2>&1
a b c
EOF
);
is $CHILD_ERROR, 0, 'echo (fields)';

qx(
bin/ppll echo <<EOF >/dev/null 2>&1
a
b
c
EOF
);
is $CHILD_ERROR, 0, 'echo (lines)';

qx(
bin/ppll --slpf echo <<EOF >/dev/null 2>&1
a b c
d e f
EOF
);
is $CHILD_ERROR, 0, 'echo (slpf)';

done_testing;
