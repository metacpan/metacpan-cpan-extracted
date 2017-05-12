use strict;
use warnings;
use Test::Simple tests => 27;

################################################################################

use DB::SPEEDYB;
##  ok( require SPEEDYB, "successfully loaded SPEEDYB" );
##  ok( undef, "superfluous test-failure to ensure the test module works" );

################################################################################

{
    my $DB = DB::SPEEDYB->new();
    my $FN0 = "does-not-exist.db";
    my $rv = $DB->open($FN0);
    ok( (! $rv), "failed to open DB file '$FN0'" );
}

################################################################################

{
    my $DB = DB::SPEEDYB->new();
    my $FN1 = "tiny.db";
    my $rv;
    ok( $DB->open($FN1), "successfully opened DB file '$FN1'" );
    ok( (! $DB->open($FN1)), "AGAIN - opened DB file '$FN1'; (failed)" );
    ok( (2 == $DB->count()), "detected expected record-count [2]" );
    ok( $DB->close(), "successfully closed DB" );
    ok( (! $DB->close()), "AGAIN - successfully closed DB (failed)" );
    #
    ok( $DB->open($FN1), "successfully opened DB file '$FN1'" );
    ok( (! $DB->open($FN1)), "AGAIN - opened DB file '$FN1'; (failed)" );
    ok( (2 == $DB->count()), "detected expected record-count [2]" );

################################################################################

    my $K = "Bob";
    $rv = $DB->get($K);
    ok( ("54 Oak Drive" eq $rv), "fetched correct record for [$K]" );
    $K = "Alice";
    $rv = $DB->get($K);
    ok( ("26 Pine Street" eq $rv), "fetched correct record for [$K]" );
    $K = "NON_DEFINED_KEY";
    $rv = $DB->get($K);
    ok( (! defined($rv)), "correct retval for non-defined key [$K]" );
    $K = "Bob";
    $rv = $DB->get($K);
    ok( ("54 Oak Drive" eq $rv), "AGAIN - fetched correct record for [$K]" );
    $K = "Alice";
    $rv = $DB->get($K);
    ok( ("26 Pine Street" eq $rv), "AGAIN - fetched correct record for [$K]" );
    $K = "NON_DEFINED_KEY";
    $rv = $DB->get($K);
    ok( (! defined($rv)), "AGAIN - correct retval for non-defined key [$K]" );

################################################################################

    print "iterating over all entries\n";
    my $N = 0;
    my %KEYS_EXPECTED = ( Bob => undef, Alice => undef );
    my $EXPECTED_KEY_COUNT = scalar( keys( %KEYS_EXPECTED ));
    my %KEYS_FOUND = ();
    while ( my($k,$v) = $DB->each())
    {
        $N++;
        #chomp($k,$v);
        #printf "[%s] => [%s]\n", $k, $v;
        ## for ( 0..2 )
        {
            if ( ! exists( $KEYS_FOUND{$k} ))
            {
                $KEYS_FOUND{$k} ++;
                ok( exists($KEYS_EXPECTED{$k}), "found expected key [$k]" );
                delete $KEYS_EXPECTED{$k};
            }
            else
            {
                $KEYS_FOUND{$k} ++;
                ok( (! exists($KEYS_FOUND{$k})), "found key [$k] unexpectedly more than once [$KEYS_FOUND{$k}]" );
            }
        }
    }
    ok( (0 == keys(%KEYS_EXPECTED)), "found all expected records (EXPECTED)" );
    ok( ($EXPECTED_KEY_COUNT == keys(%KEYS_FOUND)), "found all expected records (FOUND)" );
    ok( ($EXPECTED_KEY_COUNT == $N), "iterated over expected record-count [N=$EXPECTED_KEY_COUNT]" );

################################################################################

    print "AGAIN - iterating over all entries\n";
    $N = 0;
    %KEYS_EXPECTED = ( Bob => undef, Alice => undef );
    %KEYS_FOUND = ();
    while ( my($k,$v) = $DB->each())
    {
        $N++;
        #chomp($k,$v);
        #printf "[%s] => [%s]\n", $k, $v;
        ## for ( 0..2 )
        {
            if ( ! exists( $KEYS_FOUND{$k} ))
            {
                $KEYS_FOUND{$k} ++;
                ok( exists($KEYS_EXPECTED{$k}), "found expected key [$k]" );
                delete $KEYS_EXPECTED{$k};
            }
            else
            {
                $KEYS_FOUND{$k} ++;
                ok( (! exists($KEYS_FOUND{$k})), "found key [$k] unexpectedly more than once [$KEYS_FOUND{$k}]" );
            }
        }
    }
    ok( (0 == keys(%KEYS_EXPECTED)), "found all expected records (EXPECTED)" );
    ok( ($EXPECTED_KEY_COUNT == keys(%KEYS_FOUND)), "found all expected records (FOUND)" );
    ok( ($EXPECTED_KEY_COUNT == $N), "iterated over expected record-count [N=$EXPECTED_KEY_COUNT]" );

################################################################################

    ok( $DB->close(), "successfully closed DB" );
    ok( (! $DB->close()), "AGAIN - successfully closed DB (failed)" );

################################################################################

}
