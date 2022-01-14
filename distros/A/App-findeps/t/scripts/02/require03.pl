use strict;
use warnings;

use lib 't/lib';

# require "Module/CommentOuted.pm" # exists but will be ignored
my $dummys = 1;                  # require "Module/CommentOuted.pm" # exists but will be ignored
require "Module/Exists.pm";      # exists
require "Acme/BadExample.pm";    # does not exist anywhere

