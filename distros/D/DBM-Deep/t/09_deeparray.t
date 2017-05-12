use strict;
use warnings FATAL => 'all';

use Test::More;

plan skip_all => "You must set \$ENV{LONG_TESTS} to run the long tests"
    unless $ENV{LONG_TESTS};

use t::common qw( new_dbm );

diag "This test can take up to several minutes to run. Please be patient.";

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm( type => DBM::Deep->TYPE_ARRAY );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $max_levels = 1000;

    {
        my $db = $dbm_maker->();

        $db->[0] = [];
        my $temp_db = $db->[0];
        for my $k ( 0 .. $max_levels ) {
            $temp_db->[$k] = [];
            $temp_db = $temp_db->[$k];
        }
        $temp_db->[0] = "deepvalue";
    }

    {
        my $db = $dbm_maker->();

        my $cur_level = -1;
        my $temp_db = $db->[0];
        for my $k ( 0 .. $max_levels ) {
            $cur_level = $k;
            $temp_db = $temp_db->[$k];
            eval { $temp_db->isa( 'DBM::Deep' ) } or last;
        }
        is( $cur_level, $max_levels, "We read all the way down to level $cur_level" );
        is( $temp_db->[0], "deepvalue", "And we retrieved the value at the bottom of the ocean" );
    }
}
done_testing;
