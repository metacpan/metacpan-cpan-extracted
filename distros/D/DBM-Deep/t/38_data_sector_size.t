use strict;
use warnings FATAL => 'all';

use Test::More;

use t::common qw( new_fh );

sub do_stuff {
    my ($db) = @_;

    $db->{foo}{bar} = [ 1 .. 3 ];
}

sub verify {
    my ($db) = @_;

    cmp_ok( $db->{foo}{bar}[2], '==', 3, "Correct value found" );
}

use_ok( 'DBM::Deep' );

my %sizes;

{
    my ($fh, $filename) = new_fh();
    {
        my $db = DBM::Deep->new(
            file => $filename,
            data_sector_size => 32,
        );

        do_stuff( $db );
    }

    $sizes{32} = -s $filename;

    {
        my $db = DBM::Deep->new( file => $filename );
        verify( $db );
        $db->_get_self->_engine->storage->close( $db->_get_self );
    }
}

{
    my ($fh, $filename) = new_fh();
    {
        my $db = DBM::Deep->new(
            file => $filename,
            data_sector_size => 64,
        );

        do_stuff( $db );
    }

    $sizes{64} = -s $filename;

    {
        my $db = DBM::Deep->new( $filename );
        verify( $db );
         $db->_get_self->_engine->storage->close( $db->_get_self );
    }
}

{
    my ($fh, $filename) = new_fh();
    {
        my $db = DBM::Deep->new(
            file => $filename,
            data_sector_size => 128,
        );

        do_stuff( $db );
    }

    $sizes{128} = -s $filename;

    {
        my $db = DBM::Deep->new( $filename );
        verify( $db );
         $db->_get_self->_engine->storage->close( $db->_get_self );
    }
}

{
    my ($fh, $filename) = new_fh();
    {
        my $db = DBM::Deep->new(
            file => $filename,
            data_sector_size => 256,
        );

        do_stuff( $db );
    }

    $sizes{256} = -s $filename;

    {
        my $db = DBM::Deep->new( $filename );
        verify( $db );
         $db->_get_self->_engine->storage->close( $db->_get_self );
    }
}

cmp_ok( $sizes{256}, '>', $sizes{128}, "Filesize for 256 > filesize for 128" );
cmp_ok( $sizes{128}, '>', $sizes{64}, "Filesize for 128 > filesize for 64" );
cmp_ok( $sizes{64}, '>', $sizes{32}, "Filesize for 64 > filesize for 32" );

done_testing;
