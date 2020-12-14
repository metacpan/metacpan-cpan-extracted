use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Helpers;    # Local helper routines used by the test suite.

use Test::More tests => 4;
use CDB_File;

my ( $db, $db_tmp ) = get_db_file_pair(1);

my $c = CDB_File->new( $db->filename, $db_tmp->filename );
isa_ok( $c, 'CDB_File::Maker' );

for ( 1 .. 10 ) {
    $c->insert( "Key$_" => "Val$_" );
}

is( $c->finish, 1, "Finish writes out" );

my %h;
my $tie_obj = tie( %h, "CDB_File", $db->filename );
isa_ok( tied(%h), 'CDB_File' );
my $count = 0;

my %copy;
my $res;

for ( 0 .. 10 ) {
    $res  = $tie_obj->fetch_all();
    %copy = %h;
}

is_deeply( \%copy, $res, "fetch_all matches the tied fetch" );

exit;
