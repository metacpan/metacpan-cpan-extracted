use strict;
use warnings;

use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/../t/lib";

use Catalyst::Test 'TestApp';

TODO: {
    local $TODO = 'ConfigLoader::Remote not implemented yet';

    # these requests run tests inside their equivalent actions
    request('http://localhost/test/scalar');
    request('http://localhost/test/array');
    request('http://localhost/test/hash');
}
