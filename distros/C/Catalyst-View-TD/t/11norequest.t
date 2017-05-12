use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'TestApp' or die }

ok my $td = TestApp->view('Appconfig'), 'Get Appconfig view object';
is $td->render(undef, 'test', { message => 'hello' }), 'hello',
    'render() should return the template output';
