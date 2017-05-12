use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $max_txns = 255;

my $dbm_factory = new_dbm(
    num_txns  => $max_txns,
);
while ( my $dbm_maker = $dbm_factory->() ) {
    my @dbs = ( $dbm_maker->() );
    next unless $dbs[0]->supports('transactions');

    my $reached_max;
    push @dbs, grep { $_ } map {
        eval { $dbm_maker->() }
         ||
        # A sysopen failure indicates a problem beyond DBM::Deep’s control,
        # probably a ‘Too many files open’ error, so it’s no use failing
        # our test because of that.
        scalar(
         $@ =~ /Cannot sysopen file/ && (
          $reached_max++ or $max_txns = $_
         ),
         ()
        )
    } 2 .. $max_txns-1; # -1 because the head is included in the number
    if($reached_max) {  #  of transactions
        diag "This OS apparently can open only $max_txns files.";
    }

    cmp_ok(
      scalar(@dbs), '==', $max_txns-1,
     "We could open enough DB handles"
    );

    my %trans_ids;
    for my $n (0 .. $#dbs) {
        lives_ok {
            $dbs[$n]->begin_work
        } "DB $n can begin_work";

        my $trans_id = $dbs[$n]->_engine->trans_id;
        ok( !exists $trans_ids{ $trans_id }, "DB $n has a unique transaction ID ($trans_id)" );
        $trans_ids{ $trans_id } = $n;
    }
}

done_testing;
