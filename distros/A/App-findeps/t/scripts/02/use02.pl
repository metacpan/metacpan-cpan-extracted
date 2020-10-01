use strict;
use warnings;

use lib 't/lib';

# use Module::CommentOuted qw(Dummy); # does exist but will be ignored
my $dummys = 1;    # use Module::CommentOuted qw(Dummy); # does exist but will be ignored

use Module::Exists qw(dummy);    # does exist in t/lib
use Dummy qw(Dummy);             # does not exist anywhere

exit;
