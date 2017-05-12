use Test::More;

eval "use Test::Compile";
plan skip_all => "Test::Compile required for testing full compilation" if $@;

all_pl_files_ok();

