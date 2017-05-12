use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_dbm );

use_ok( 'DBM::Deep' );

my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    my $db = $dbm_maker->();

    {
        {
            package My::Tie::Hash;

            sub TIEHASH {
                my $class = shift;

                return bless {
                }, $class;
            }
        }

        my %hash;
        tie %hash, 'My::Tie::Hash';
        isa_ok( tied(%hash), 'My::Tie::Hash' );

        throws_ok {
            $db->{foo} = \%hash;
        } qr/Cannot store something that is tied/, "Cannot store tied hashes";
    }

    {
        {
            package My::Tie::Array;

            sub TIEARRAY {
                my $class = shift;

                return bless {
                }, $class;
            }

            sub FETCHSIZE { 0 }
        }

        my @array;
        tie @array, 'My::Tie::Array';
        isa_ok( tied(@array), 'My::Tie::Array' );

        throws_ok {
            $db->{foo} = \@array;
        } qr/Cannot store something that is tied/, "Cannot store tied arrays";
    }

    {
        {
            package My::Tie::Scalar;

            sub TIESCALAR {
                my $class = shift;

                return bless {
                }, $class;
            }
        }

        my $scalar;
        tie $scalar, 'My::Tie::Scalar';
        isa_ok( tied($scalar), 'My::Tie::Scalar' );

        throws_ok {
            $db->{foo} = \$scalar;
        } qr/Storage of references of type 'SCALAR' is not supported/, "Cannot store scalar references, let alone tied scalars";
    }
}

done_testing;
