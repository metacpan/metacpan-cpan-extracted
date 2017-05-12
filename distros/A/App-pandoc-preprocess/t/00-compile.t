use Test::More;
eval "use Test::Compile";
Test::More->builder->BAIL_OUT(
    "Test::Compile required for testing compilation") if $@;
pm_file_ok('lib/App/pandoc/preprocess.pm');
pl_file_ok('bin/ppp');
done_testing;
