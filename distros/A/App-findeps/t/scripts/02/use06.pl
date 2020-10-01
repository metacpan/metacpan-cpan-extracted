use strict;
use warnings;

use lib 't/lib';

# use autouse 'Module::CommentOuted' => qw(dummy isdummy); # does exist but will be ignored
my $dummys
    = 1; # use autouse 'Module::CommentOuted' => qw(dummy isdummy); # does exist but will be ignored

use autouse 'Module::Exists' => qw(dummy is_dummy);    # does exist in t/lib
use autouse 'Dummy'          => qw(dummy is_dummy);    # 'Dummy' does not exist anywhere

require Dummy;
exit;
