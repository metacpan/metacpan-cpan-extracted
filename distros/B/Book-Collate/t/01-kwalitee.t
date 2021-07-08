# t/01-kwalitee.t

use Test::More;
use strict;
use warnings;

BEGIN {
  plan skip_all => 'these tests are for release testing'
    unless $ENV{RELEASE_TESTING};
}

use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok();
done_testing();

