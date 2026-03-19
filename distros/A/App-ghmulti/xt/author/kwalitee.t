use strict;
use warnings;
use Test::More;


BEGIN {
    plan skip_all => 'these tests are for author or release candidate testing'
        unless $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};
}

use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok();
done_testing();
