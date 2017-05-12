#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Catalyst::Test 'MyApp::Web';

like get('/'), qr/welcome/i, 'root page displays welcome';
is get('/ifthisisfoundsomeonehasserioustestnamingissues'), 'Page Not Found', 'default captures 404';

is get('/calc/add/3/4/5'), 12, 'addition';
is get('/calc/multiply/2/3/4'), 24, 'multiplication';

is get('/calc/unknownthingy/3/4/5'), 'unknown operator', 'unknown operator';
is get('/calc/add/3/f/5'), 'Page Not Found', 'bad request';

like get('/foo/hello'), qr/root controller role/, 'root controller role';

is get('/foo/2/3/add'), 5, 'add two';
is get('/foo/2/3/multiply'), 6, 'multiply two';

is get('/foo/2/f/add'), 'Page Not Found', 'bad request capture args';

done_testing;
