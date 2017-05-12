use Test::More;
BEGIN {
    plan skip_all => 'this test only runs with RELEASE_TESTING set'
        unless $ENV{RELEASE_TESTING};
}
use Test::Kwalitee ();
Test::Kwalitee::kwalitee_ok();
done_testing;
