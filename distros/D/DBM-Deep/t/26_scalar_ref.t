use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_dbm new_fh );

use_ok( 'DBM::Deep' );

my $x = 25;
my $dbm_factory = new_dbm();
while ( my $dbm_maker = $dbm_factory->() ) {
    {
        my $db = $dbm_maker->();

        throws_ok {
            $db->{scalarref} = \$x;
        } qr/Storage of references of type 'SCALAR' is not supported/,
        'Storage of scalar refs not supported';

        throws_ok {
            $db->{scalarref} = \\$x;
        } qr/Storage of references of type 'REF' is not supported/,
        'Storage of ref refs not supported';

        throws_ok {
            $db->{scalarref} = sub { 1 };
        } qr/Storage of references of type 'CODE' is not supported/,
        'Storage of code refs not supported';

        throws_ok {
            my ($fh, $filename) = new_fh;
            $db->{scalarref} = $fh;
        } qr/Storage of references of type 'GLOB' is not supported/,
        'Storage of glob refs not supported';

        $db->{scalar} = $x;
        TODO: {
            todo_skip "Refs to DBM::Deep objects aren't implemented yet", 2;
            lives_ok {
                $db->{selfref} = \$db->{scalar};
            } "Refs to DBM::Deep objects are ok";

            is( ${$db->{selfref}}, $x, "A ref to a DBM::Deep object is ok" );
        }
    }

    {
        my $db = $dbm_maker->();

        is( $db->{scalar}, $x, "Scalar retrieved ok" );
        TODO: {
            todo_skip "Refs to DBM::Deep objects aren't implemented yet", 2;
            is( ${$db->{scalarref}}, 30, "Scalarref retrieved ok" );
            is( ${$db->{selfref}}, 26, "Scalarref to stored scalar retrieved ok" );
        }
    }
}

done_testing;
