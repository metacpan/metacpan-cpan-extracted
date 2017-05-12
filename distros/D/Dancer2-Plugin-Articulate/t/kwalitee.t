use Test::More;
use strict;
use warnings;

BEGIN {
  plan skip_all => 'Kwalitee tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};
}

use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok();
done_testing;
