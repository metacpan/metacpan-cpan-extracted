#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Helpers;    # Local helper routines used by the test suite.

use Test::More tests => 7;
use Test::Warnings;

use CDB_File;

my ( $db, $db_tmp ) = get_db_file_pair(1);

my $db_file = $db->filename;
eval {
    my $t = CDB_File->new( $db_file, $db_tmp->filename, utf8 => 0 ) or die "Failed to create cdb: $!";
    $t->finish;
};

is( "$@", '', "Created empty cdb" );
ok( -f $db_file && !-z _, "The db file is there" );

tie( my %h, "CDB_File", $db_file ) or die;

is( scalar keys %h, 0,     "No keys in the hash" );
is( $h{'foo'},      undef, "Missing key returns undef" );

my $t = tied %h;

is( $t->FIRSTKEY, undef, "No keys via FIRSTKEY" );
my $hash = $t->fetch_all;
is( scalar keys %$hash, 0, "Nothing from fetch_all" )
  or diag explain $hash;

note "exit";
exit;
