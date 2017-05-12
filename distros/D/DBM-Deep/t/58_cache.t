use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_dbm );
use utf8;

use DBM::Deep;

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    $db->{h} = {1,2};
    my $h = $db->{h};
    undef $h;  # now no longer cached
    $h = $db->{h};  # cached again
    ok $h, 'stale cache entries are not mistakenly reused';
}

done_testing;
