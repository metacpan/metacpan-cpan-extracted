use strict;
use warnings;
use Test2::V0;
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use At;
#
pass $At::VERSION;
#
done_testing;
