use Test::More;
use strict;
use warnings;
BEGIN {
    plan skip_all => $@ ? 'no module Test::Kwalitee installed' : 'these tests are for release candidate testing'
        unless eval { require Test::Kwalitee } && $ENV{RELEASE_TESTING};
}

use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok;
done_testing;
