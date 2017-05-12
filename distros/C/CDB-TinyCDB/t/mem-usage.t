
BEGIN {
    if ( $ENV{DEVELOPER_TEST_RUN_VALGRIND} ) {
        eval "require Test::Valgrind";
        Test::Valgrind->import();
    }
}

use Test::More tests => 8;
use Test::Exception;
use Test::NoWarnings;

BEGIN { use_ok('CDB::TinyCDB') };


my $dbfile = 't/data.cdb';

SKIP: {
    skip "Author tests not required for installation", 6 unless $ENV{DEVELOPER_TEST_RUN};
    eval "require GTop;";

    my $cdb;
    my $cdb2;
    my $mem_before; 
    my $mem_after; 
    my $gtop = GTop->new();
    my @mems = qw(
        size
        vsize
    );

    $mem_before = $gtop->proc_mem( $$ ); 
    lives_ok {
        $cdb = CDB::TinyCDB->open( $dbfile );
    } "open";
    $mem_after = $gtop->proc_mem( $$ ); 

    is( $mem_after->$_ - $mem_before->$_, 0,
        "process memory $_ unchanged for open") for @mems;

    $mem_before = $gtop->proc_mem( $$ ); 
    lives_ok {
        $cdb = CDB::TinyCDB->load( $dbfile );
    } "load";
    $mem_after = $gtop->proc_mem( $$ ); 

    my $dbfile_size = -s $dbfile;

    is( $mem_after->$_ - $mem_before->$_ >= $dbfile_size ? 1 : 0, 1,
        "process memory $_ grows when loading cdb $dbfile_size") for @mems;
}




