use strict;
use warnings;

use lib 't/lib';

# require Module::CommentOuted; # does exist but will be ignored
my $dummys = 1;    # require Module::CommentOuted; # does exist but will be ignored

require Module::Exists;    # does exist in t/lib
require Dummy;             # does not exist anywhere

exit;
