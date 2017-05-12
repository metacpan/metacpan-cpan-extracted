use strict;
use warnings FATAL => 'all';

use Config;
use Test::More;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

my ($default, $small, $medium, $large);

{
    my ($fh, $filename) = new_fh();
    my $db = DBM::Deep->new(
        file => $filename,
        autoflush => 1,
    );
    $db->{key1} = "value1";
    $db->{key2} = "value2";
    $default = (stat($filename))[7];
}

{
    my ($fh, $filename) = new_fh();
    {
        my $db = DBM::Deep->new(
            file => $filename,
            autoflush => 1,
            pack_size => 'medium',
        );

        $db->{key1} = "value1";
        $db->{key2} = "value2";
        $medium = (stat($filename))[7];
    }

    # This tests the header to verify that the pack_size is really there
    {
        my $db = DBM::Deep->new(
            file => $filename,
        );

        is( $db->{key1}, 'value1', 'Can read key1' );
        is( $db->{key2}, 'value2', 'Can read key2' );
    }

    cmp_ok( $medium, '==', $default, "The default is medium" );
}

{
    my ($fh, $filename) = new_fh();
    {
        my $db = DBM::Deep->new(
            file => $filename,
            autoflush => 1,
            pack_size => 'small',
        );

        $db->{key1} = "value1";
        $db->{key2} = "value2";
        $small = (stat($filename))[7];
    }

    # This tests the header to verify that the pack_size is really there
    {
        my $db = DBM::Deep->new(
            file => $filename,
        );

        is( $db->{key1}, 'value1', 'Can read key1' );
        is( $db->{key2}, 'value2', 'Can read key2' );
    }

    cmp_ok( $medium, '>', $small, "medium is greater than small" );
}

eval "pack('Q', 0);";
my $haveQ = !$@;

SKIP: {
    skip "Largefile support is not compiled into $^X", 3
        unless $haveQ;

    my ($fh, $filename) = new_fh();
    {
        my $db = DBM::Deep->new(
            file => $filename,
            autoflush => 1,
            pack_size => 'large',
        );

        $db->{key1} = "value1";
        $db->{key2} = "value2";
        $large = (stat($filename))[7];
    }

    # This tests the header to verify that the pack_size is really there
    {
        my $db = DBM::Deep->new(
            file => $filename,
        );

        is( $db->{key1}, 'value1', 'Can read key1' );
        is( $db->{key2}, 'value2', 'Can read key2' );
    }
    cmp_ok( $medium, '<', $large, "medium is smaller than large" );
}

#SKIP: {
#    skip "Largefile support is compiled into $^X", 3
#        if $haveQ;
#
#    my ($fh, $filename) = new_fh();
#    {
#        my $db = DBM::Deep->new(
#            file => $filename,
#            autoflush => 1,
#            pack_size => 'large',
#        );
#    }
#
#}

done_testing;
