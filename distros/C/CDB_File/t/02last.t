use strict;
use warnings;

use Test::More tests => 44;
use CDB_File;

my $c = CDB_File->new( 'last.cdb', 'last.tmp' );
isa_ok( $c, 'CDB_File::Maker' );

for ( 1 .. 10 ) {
    $c->insert( "Key$_" => "Val$_" );
}

is( $c->finish, 1, "Finish writes out" );

my %h;
tie( %h, "CDB_File", "last.cdb" );
isa_ok( tied(%h), 'CDB_File' );
my $count = 0;

foreach my $k ( keys %h ) {
    $k =~ m/^Key(\d+)$/ or die;
    my $n = $1;
    ok( $n <= 10 && $n > 0, "Expected key ($n) is found" )
      or diag($k);

    is( $h{$k}, "Val$n", "Val$n matches" );
}

tie( %h, "CDB_File", "last.cdb" );
isa_ok( tied(%h), 'CDB_File' );

while ( my ( $k, $v ) = each(%h) ) {
    ok( $k, "verify k in re-tied hash ($k)" );
    ok( $v, "verify v in re-tied hash ($v)" );
}

END { unlink 'last.cdb' }
