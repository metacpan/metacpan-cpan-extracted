use strict;
use warnings;
use Test::More tests => 1;
BEGIN { eval 'use EV' }
use AnyEvent;

pass 'pass';
diag AnyEvent::detect();
