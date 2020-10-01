use strict;
use warnings;

use lib 't/lib';

# eval { use Module::CommentOuted; return Module::CommentOuted->new(); }; # will be ignored
1;    # eval { use Module::CommentOuted; return Module::CommentOuted->new(); }; # will be ignored
my $dummy = eval "use Eval::With::DoubleQuote; return Eval::With::DoubleQuote->new();";

# will be ignored

require Dummy;    # does not exist anywhere

exit;
