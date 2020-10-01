use strict;
use warnings;

use lib 't/lib';

# eval { require Module::CommentOuted }; # will be ignored
my $dummys = 1;    # eval { require Module::CommentOuted }; # will be ignored

eval { require Eval::With::Brace } or die $@;    # does exist in t/lib
require Dummy;                                   # does not exist anywhere

0;
