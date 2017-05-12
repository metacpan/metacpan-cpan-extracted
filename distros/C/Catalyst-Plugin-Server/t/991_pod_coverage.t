use Test::More;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
}

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required'    if $@;
plan skip_all => 'set TEST_POD to enable this test'     if not $ENV{TEST_POD};
plan 'no_plan';

### XXX this looks in lib/, and that translates to t/lib, which is the
### wrong dir. So we find our modules explicitly
#all_pod_coverage_ok();

pod_coverage_ok( $_ ) for all_modules( '../lib' );
