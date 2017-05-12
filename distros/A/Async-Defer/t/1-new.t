use warnings;
use strict;
use Test::More;
use Test::Exception;

use Async::Defer;


plan tests => 1;


my ($d);


# new

$d = Async::Defer->new();
ok $d,  'new Defer object created';


