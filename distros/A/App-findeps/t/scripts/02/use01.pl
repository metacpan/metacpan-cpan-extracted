use strict;
use warnings;
use lib 't/lib';

# use Module::CommentOuted; # does exist but will be ignored
my $dummys = 1;    # use Module::CommentOuted; # does exist but will be ignored

use Module::Exists;    # does exist in t/lib
use Dummy;             # does not exist anywhere

exit;
