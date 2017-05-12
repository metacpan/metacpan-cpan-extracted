use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    SKIP: {
        skip "Apparently, we cannot detect a tied scalar?", 1;
        tie my $foo, 'Tied::Scalar';
        throws_ok {
            $db->{failure} = $foo;
        } qr/Cannot store something that is tied\./, "tied scalar storage fails";
    }

    {
        tie my @foo, 'Tied::Array';
        throws_ok {
            $db->{failure} = \@foo;
        } qr/Cannot store something that is tied\./, "tied array storage fails";
    }

    {
        tie my %foo, 'Tied::Hash';
        throws_ok {
            $db->{failure} = \%foo;
        } qr/Cannot store something that is tied\./, "tied hash storage fails";
    }

    # Need to create a second instance of a dbm here, but only of the type
    # being tested.
    if(0){
        my $db2 = $dbm_maker->();

        $db2->import({
            hash1 => {
                subkey1 => "subvalue1",
                subkey2 => "subvalue2",
            }
        });
        is( $db2->{hash1}{subkey1}, 'subvalue1', "Value1 imported correctly" );
        is( $db2->{hash1}{subkey2}, 'subvalue2', "Value2 imported correctly" );

        # Test cross-ref nested hash across DB objects
        throws_ok {
            $db->{copy} = $db2->{hash1};
        } qr/Cannot store values across DBM::Deep files\. Please use export\(\) instead\./, "cross-ref fails";

        # This error text is for when internal cross-refs are implemented:
        # qr/Cannot cross-reference\. Use export\(\) instead\./

        my $x = $db2->{hash1}->export;
        $db->{copy} = $x;
    }

    ##
    # Make sure $db has copy of $db2's hash structure
    ##
#    is( $db->{copy}{subkey1}, 'subvalue1', "Value1 copied correctly" );
#    is( $db->{copy}{subkey2}, 'subvalue2', "Value2 copied correctly" );
}

done_testing;

package Tied::Scalar;
sub TIESCALAR { bless {}, $_[0]; }
sub FETCH{}

package Tied::Array;
sub TIEARRAY { bless {}, $_[0]; }

package Tied::Hash;
sub TIEHASH { bless {}, $_[0]; }
