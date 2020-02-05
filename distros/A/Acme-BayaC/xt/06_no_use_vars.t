use Test::More;
eval "use Test::Vars";
plan skip_all => 'Test::Vars required for testing for unused vars' if $@;
all_vars_ok();
