#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Helpers;    # Local helper routines used by the test suite.

use Test::More;
use Test::Warnings 0.005 ':all';

plan tests => 8;

use CDB_File;

{
    note "Test undef values on create.";
    my ( $db, $db_tmp ) = get_db_file_pair(1);

    my %a = qw(one Hello two Goodbye);
    $a{'foo'} = undef;

    my $w = warning { CDB_File::create( %a, $db->filename, $db_tmp->filename ) };
    like( $w, qr{^undef values cannot be stored in CDB_File. Storing an empty string instead at }, "create() causes a warning when there are undef values in the hash" )
      or diag explain $w;
    is( "$@", '', "Create cdb" );

    tie( my %h, "CDB_File", $db->filename ) and pass("Test that good file works");
    is( $h{'one'}, "Hello", "There is stuff in the db" );
    is( $h{'foo'}, '',      "The undef value was stored as ''" );
}

eval {
    note "Test undef insert";
    my ( $db, $db_tmp ) = get_db_file_pair(1);
    my $t = CDB_File->new( $db->filename, $db_tmp->filename, utf8 => 0 ) or die "Failed to create cdb: $!";
    like( warning { $t->insert( "efg", undef ) }, qr/^undef values cannot be stored in CDB_File\. Storing an empty string instead at /, "Undef values are warned." );

    like( warning { $t->insert( undef, "abcd" ) }, qr{^Use of uninitialized value in hash key at }, "undef keys get a warnings too." );

    $t->finish;
};

note "exit";
exit;
