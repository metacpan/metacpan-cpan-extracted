use strict;
use warnings;

BEGIN { @ENV{qw/CATALYST_REPL/} = 'noprofile'; }

use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

request($ARGV[0]);
