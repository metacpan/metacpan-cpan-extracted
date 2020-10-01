use strict;
use warnings;

use lib 't/lib';

# use parent 'Module::CommentOuted'; # does exist but will be ignored
my $dummys = 1;    # use parent 'Module::CommentOuted'; # does exist but will be ignored

use parent 'Module::Exists';    # does exist in t/lib
use parent 'Dummy';             # does not exist anywhere

exit;
