
use Test::More;
eval "use Test::NoBreakpoints 0.10";
plan skip_all => "Test::NoBreakpoints 0.10 required for testing" if $@;
all_files_no_breakpoints_ok();

done_testing;
