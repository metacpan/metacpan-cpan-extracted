use strict;
use warnings FATAL => 'all';

use Test::More;

plan skip_all => "You must set \$ENV{LONG_TESTS} to run the long tests"
    unless $ENV{LONG_TESTS};

use t::common qw( new_dbm );

diag "This test can take up to several minutes to run. Please be patient.";

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm( type => DBM::Deep->TYPE_HASH );
while ( my $dbm_maker = $dbm_factory->() ) {
    my $max_levels = 1000;

    {
        my $db = $dbm_maker->();

        ##
        # basic deep hash
        ##
        $db->{company} = {};
        $db->{company}->{name} = "My Co.";
        $db->{company}->{employees} = {};
        $db->{company}->{employees}->{"Henry Higgins"} = {};
        $db->{company}->{employees}->{"Henry Higgins"}->{salary} = 90000;

        is( $db->{company}->{name}, "My Co.", "Set and retrieved a second-level value" );
        is( $db->{company}->{employees}->{"Henry Higgins"}->{salary}, 90000, "Set and retrieved a fourth-level value" );

        ##
        # super deep hash
        ##
        $db->{base_level} = {};
        my $temp_db = $db->{base_level};

        for my $k ( 0 .. $max_levels ) {
            $temp_db->{"level$k"} = {};
            $temp_db = $temp_db->{"level$k"};
        }
        $temp_db->{deepkey} = "deepvalue";
    }

    {
        my $db = $dbm_maker->();

        my $cur_level = -1;
        my $temp_db = $db->{base_level};
        for my $k ( 0 .. $max_levels ) {
            $cur_level = $k;
            $temp_db = $temp_db->{"level$k"};
            eval { $temp_db->isa( 'DBM::Deep' ) } or last;
        }
        is( $cur_level, $max_levels, "We read all the way down to level $cur_level" );
        is( $temp_db->{deepkey}, "deepvalue", "And we retrieved the value at the bottom of the ocean" );
    }
}

done_testing;
