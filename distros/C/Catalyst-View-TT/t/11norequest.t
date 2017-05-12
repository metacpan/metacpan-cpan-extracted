use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'TestApp' or die }

ok my $tt = TestApp->view, 'Get TT view object';
is $tt->render(undef, 'test.tt', { message => 'hello' }), 'hello',
    'render() should return the template output';
