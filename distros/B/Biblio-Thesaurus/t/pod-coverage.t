use Test::More;
eval "use Test::Pod::Coverage 0.08";
#plan skip_all => "still not passing this test.";
plan skip_all => "Test::Pod::Coverage 0.08 required for testing POD coverage" if $@;
plan skip_all => "export AUTHOR_TEST for author tests" unless $ENV{AUTHOR_TEST};
all_pod_coverage_ok();
