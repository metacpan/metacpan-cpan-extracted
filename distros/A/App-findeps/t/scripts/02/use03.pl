use strict;
use warnings;

use lib 't/lib';

# use base 'Module::CommentOuted'; # does exist but will be ignored
my $dummys = 1;    # use base 'Module::CommentOuted'; # does exist but will be ignored

use base 'Module::Exists';    # does exist in t/lib
use base 'Dummy';             # does not exist anywhere

exit;
