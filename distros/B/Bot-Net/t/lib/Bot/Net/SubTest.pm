use strict;
use warnings;

package Bot::Net::SubTest;

# This code was original taken from Jifty::SubTest

use FindBin;
use File::Spec;

BEGIN {
    @INC = grep { defined } map { ref($_) ? $_ : File::Spec->rel2abs($_) } @INC;
    chdir "$FindBin::Bin/..";
}

use lib 'lib';

1;
