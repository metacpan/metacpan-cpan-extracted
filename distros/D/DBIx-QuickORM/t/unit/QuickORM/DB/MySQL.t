BEGIN {
    unless (eval { require DBD::MariaDB; 1 } || eval { require DBD::mysql; 1 }) {
        print "1..0 # SKIP Neither DBD::MariaDB nor DBD::mysql are installed.\n";
        exit(0);
    }
}

use Test2::V0 -target => 'DBIx::QuickORM::DB::MySQL';

use ok $CLASS;

done_testing;
