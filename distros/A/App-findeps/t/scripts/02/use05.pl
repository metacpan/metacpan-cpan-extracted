use strict;
use warnings;

use lib 't/lib';

# use parent qw(Dummy Module::CommentOuted); # does exist but will be ignored
my $dummys = 1;    # use parent qw(Dummy Module::CommentOuted); # does exist but will be ignored

use parent qw(Dummy Module::Exists);    # 'Dummy' does not exist anywhere

exit;
