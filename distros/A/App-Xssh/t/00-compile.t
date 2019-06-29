use Test::More;

eval "use Test::Compile";
plan skip_all => "Test::Compile required for testing full compilation" if $@;

my $test = Test::Compile->new();
$test->all_files_ok();
$test->done_testing();

