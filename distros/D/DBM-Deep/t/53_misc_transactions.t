# This was discussed here:
# http://groups.google.com/group/DBM-Deep/browse_thread/thread/a6b8224ffec21bab
# brought up by Alex Gallichotte

use strict;
use warnings FATAL => 'all';

use Test::More;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();
    eval { $db->{randkey()} = randkey() for 1 .. 10; }; ok(!$@, "No eval failures");

    eval {
        #$db->begin_work;
        $db->{randkey()} = randkey() for 1 .. 10;
        #$db->commit;
    };
    ok(!$@, "No eval failures from the transaction");

    eval { $db->{randkey()} = randkey() for 1 .. 10; };
    ok(!$@, "No eval failures");
}

done_testing;

sub randkey {
    our $i++;
    my @k = map { int rand 100 } 1 .. 10;
    local $" = "-";

    return "$i-@k";
}
