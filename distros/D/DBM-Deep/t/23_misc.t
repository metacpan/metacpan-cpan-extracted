use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

{
    my ($fh, $filename) = new_fh();
    print $fh "Not a DBM::Deep file";

    my $old_fh = select $fh;
    my $old_af = $|; $| = 1; $| = $old_af;
    select $old_fh;

    throws_ok {
        my $db = DBM::Deep->new( $filename );
    } qr/^DBM::Deep: Signature not found -- file is not a Deep DB/, "Only DBM::Deep DB files will be opened";
}

my ($fh, $filename) = new_fh();
my $db = DBM::Deep->new( $filename );

$db->{key1} = "value1";
is( $db->{key1}, "value1", "Value set correctly" );

# Testing to verify that the close() will occur if open is called on an open DB.
#XXX WOW is this hacky ...
$db->_get_self->_engine->storage->open;
is( $db->{key1}, "value1", "Value still set after re-open" );

throws_ok {
    my $db = DBM::Deep->new( 't' );
} qr/^DBM::Deep: Cannot sysopen file 't': /, "Can't open a file we aren't allowed to touch";

{
    my $db = DBM::Deep->new(
        file => $filename,
        locking => 1,
    );
    $db->_get_self->_engine->storage->close( $db->_get_self );
    ok( !$db->lock, "Calling lock() on a closed database returns false" );
}

{
    my $db = DBM::Deep->new(
        file => $filename,
        locking => 1,
    );
    $db->lock;
    $db->_get_self->_engine->storage->close( $db->_get_self );
    ok( !$db->unlock, "Calling unlock() on a closed database returns false" );
}

done_testing;
