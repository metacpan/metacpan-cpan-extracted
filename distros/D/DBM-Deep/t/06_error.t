
$|++;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use Test::Warn;
use lib 't';
use common qw( new_fh );

use_ok( 'DBM::Deep' );

# test a corrupted file
{
    my ($fh, $filename) = new_fh();

    open FH, ">$filename";
    print FH 'DPDB';
    close FH;

    throws_ok {
        DBM::Deep->new( $filename );
    } qr/DBM::Deep: Pre-1.00 file version found/, "Fail if there's a bad header";
}

{
    my ($fh, $filename) = new_fh();
    my %hash;
    tie %hash, 'DBM::Deep', $filename;
    undef %hash;

    my @array;
    throws_ok {
        tie @array, 'DBM::Deep', $filename;
    } qr/DBM::Deep: File type mismatch/, "Fail if we try and tie a hash file with an array";

    throws_ok {
        DBM::Deep->new( file => $filename, type => DBM::Deep->TYPE_ARRAY )
    } qr/DBM::Deep: File type mismatch/, "Fail if we try and open a hash file with an array";
}

{
    my ($fh, $filename) = new_fh();
    my @array;
    tie @array, 'DBM::Deep', $filename;
    undef @array;

    my %hash;
    throws_ok {
        tie %hash, 'DBM::Deep', $filename;
    } qr/DBM::Deep: File type mismatch/, "Fail if we try and tie an array file with a hash";

    throws_ok {
        DBM::Deep->new( file => $filename, type => DBM::Deep->TYPE_HASH )
    } qr/DBM::Deep: File type mismatch/, "Fail if we try and open an array file with a hash";
}

{
    my %floors = (
        max_buckets => 16,
        num_txns => 1,
        data_sector_size => 32,
    );

    while ( my ($attr, $floor) = each %floors ) {
        {
            my ($fh, $filename) = new_fh();
            warning_like {
                my $db = DBM::Deep->new(
                    file => $filename,
                    $attr => undef,
                );
            } qr{Floor of $attr is $floor\. Setting it to $floor from '\Q(undef)\E'},
             "Warning for $attr => undef is correct";
        }
        {
            my ($fh, $filename) = new_fh();
            warning_like {
                my $db = DBM::Deep->new(
                    file => $filename,
                    $attr => '',
                );
            } qr{Floor of $attr is $floor\. Setting it to $floor from ''},
             "Warning for $attr => '' is correct";
        }
        {
            my ($fh, $filename) = new_fh();
            warning_like {
                my $db = DBM::Deep->new(
                    file => $filename,
                    $attr => 'abcd',
                );
            } qr{Floor of $attr is $floor\. Setting it to $floor from 'abcd'},
             "Warning for $attr => 'abcd' is correct";
        }
        {
            my ($fh, $filename) = new_fh();
            my $val = $floor - 1;
            warning_like {
                my $db = DBM::Deep->new(
                    file => $filename,
                    $attr => $val,
                );
            } qr{Floor of $attr is $floor\. Setting it to $floor from '$val'},
             "Warning for $attr => $val is correct";
        }
    }

    my %ceilings = (
        max_buckets => 256,
        num_txns => 255,
        data_sector_size => 256,
    );

    while ( my ($attr, $ceiling) = each %ceilings ) {
        my ($fh, $filename) = new_fh();
        warning_like {
            my $db = DBM::Deep->new(
                file => $filename,
                $attr => 1000,
            );
        } qr{Ceiling of $attr is $ceiling\. Setting it to $ceiling from '1000'},
          "Warning for $attr => 1000 is correct";
    }
}

{
    throws_ok {
        DBM::Deep->new( 't/etc/db-0-983' );
    } qr/DBM::Deep: Pre-1.00 file version found/, "Fail if opening a pre-1.00 file";
}

{
    throws_ok {
        DBM::Deep->new( 't/etc/db-0-99_04' );
    } qr/DBM::Deep: This file version is too old - 0\.99 - expected (?x:
        )1\.0003 to \d/, "Fail if opening a file version 1";
}

{
    # Make sure we get the right file name in the error message.
    throws_ok {
        eval "#line 1 gneen\nDBM::Deep->new( 't/etc/db-0-99_04' )"
	 or die $@
    } qr/ at gneen line 1\b/, "File name in error message is correct";
}

done_testing;
