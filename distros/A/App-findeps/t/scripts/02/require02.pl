use strict;
use warnings;

use lib 't/lib';

# require 'Module::CommentOuted'; # does exist but will be ignored
my $dummys = 1;                # require 'Module::CommentOuted'; # does exist but will be ignored
require 'Module/Exists.pm';    # does exist
require 'Dummy.pm';            # does not exist anywhere

exit;
