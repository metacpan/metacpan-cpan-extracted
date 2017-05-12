use Test::Pod::Coverage tests => 1;

pod_coverage_ok('Cache::Swifty', { also_private => [ qw/new swifty_new swifty_free swifty_get swifty_set swifty_do_refresh SWIFTY HASH_CALLBACK NOW/ ] });