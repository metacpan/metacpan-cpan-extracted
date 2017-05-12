use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    my $h = {};
    my $tmp = $h;
    for (1..99) { # 98 is ok, 99 is bad.
        %$tmp = ("" => {});
        $tmp = $tmp->{""};
    }
    lives_ok {
        $db->{""} = $h;
    } 'deep recursion causes no errors';
}

done_testing;
