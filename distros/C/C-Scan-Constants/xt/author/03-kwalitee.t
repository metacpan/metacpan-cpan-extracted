# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should
# work as `perl 03-kwalitee.t'

#########################


use Test::More;

# Only apply kwalitee tests if we are able to, otherwise apply tests.
eval { require Test::Kwalitee; };
if ($@) {
    plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
}
else {
    Test::Kwalitee->import();
}
