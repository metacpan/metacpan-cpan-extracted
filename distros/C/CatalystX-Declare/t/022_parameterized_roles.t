#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';

is get('/param/greet'), 'foo:foo', 'parameterized role was consumed correctly';
is get('/param/somebase/dynabase'), 'under somebase', 'dynamic base via parameter';
is get('/param/somebase/somepart'), 'under somebase as somepart', 'dynamic base and path part via parameter';
is get('/param/somebase/scoped'), 'scoped under somebase', 'dynamic base in under scope via parameter';
is get('/param/somebase/somepart/deep'), 'somepart/deep under somebase', 'more complex strings';
is get('/param/somebase/someaction'), 'someaction action', 'dynamic action name';
is get('/param/somebase/actionalias'), 'someaction action', 'dynamic action name in method call';
is get('/param/somebase/SOMEPART'), 'upper as SOMEPART under somebase', 'value prepared at runtime in role body';
is get('/param/somebase/short/foo'), 'short foo', 'dynamic base in shortcut declaration';

done_testing;
