use strict;
use warnings;

use Test::More tests => 4;
use CDB_File;

my $c = CDB_File->new( 'last.cdb', 'last.tmp' );
isa_ok( $c, 'CDB_File::Maker' );

for ( 1 .. 10 ) {
    $c->insert( "Key$_" => "Val$_" );
}

is( $c->finish, 1, "Finish writes out" );

my %h;
my $tie_obj = tie( %h, "CDB_File", "last.cdb" );
isa_ok( tied(%h), 'CDB_File' );
my $count = 0;

my %copy;
my $res;

for ( 0 .. 10 ) {
    $res  = $tie_obj->fetch_all();
    %copy = %h;
}

is_deeply( \%copy, $res, "fetch_all matches the tied fetch" );

END { unlink 'last.cdb' }
