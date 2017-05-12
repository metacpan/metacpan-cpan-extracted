#
# $Id: 06_breakpoints.t 86 2004-06-18 20:18:01Z james $
#

use Test::More;
eval "use Test::NoBreakpoints 0.10";
plan skip_all => "Test::NoBreakpoints 0.10 required for testing" if $@;
plan 'no_plan';
all_files_no_brkpts_ok();

#
# EOF
