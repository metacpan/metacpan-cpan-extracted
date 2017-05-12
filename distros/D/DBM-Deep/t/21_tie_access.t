use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

my ($fh, $filename) = new_fh();

{
    my %hash;
    tie %hash, 'DBM::Deep', $filename;

    $hash{key1} = 'value';
    is( $hash{key1}, 'value', 'Set and retrieved key1' );
    tied( %hash )->_get_self->_engine->storage->close( tied( %hash )->_get_self );
}

{
    my %hash;
    tie %hash, 'DBM::Deep', $filename;

    is( $hash{key1}, 'value', 'Set and retrieved key1' );

    is( keys %hash, 1, "There's one key so far" );
    ok( exists $hash{key1}, "... and it's key1" );
    tied( %hash )->_get_self->_engine->storage->close( tied( %hash )->_get_self );
}

{
    throws_ok {
        tie my @array, 'DBM::Deep', {
            file => $filename,
            type => DBM::Deep->TYPE_ARRAY,
        };
        tied( @array )->_get_self->_engine->storage->close( tied( @array )->_get_self );
    } qr/DBM::Deep: File type mismatch/, "\$SIG_TYPE doesn't match file's type";
}

{
    my ($fh, $filename) = new_fh();
    my $db = DBM::Deep->new( file => $filename, type => DBM::Deep->TYPE_ARRAY );

    throws_ok {
        tie my %hash, 'DBM::Deep', {
            file => $filename,
            type => DBM::Deep->TYPE_HASH,
        };
    } qr/DBM::Deep: File type mismatch/, "\$SIG_TYPE doesn't match file's type";
    $db->_get_self->_engine->storage->close( $db->_get_self );
}

done_testing;
