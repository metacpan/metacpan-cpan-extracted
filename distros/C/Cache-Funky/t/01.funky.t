package MyCache;

use strict;
use warnings;
use base qw( Cache::Funky );
use Test::More qw/no_plan/;

MyCache->setup( 'Storage::Simple' => {} );
MyCache->register( 'foo', sub { time } );
MyCache->register( 'boo', sub { time . shift } );

my $foo;
like( $foo = MyCache->foo , qr/^\d+$/, "ok get foo() : $foo");
sleep 1;
ok( $foo eq MyCache->foo , "cache ok");
MyCache->delete('foo');
ok( $foo ne MyCache->foo , "re cache ok");

sleep 1;
MyCache->deletes([ qw/foo/ ]);
ok( $foo ne MyCache->foo , "re deletes cache ok");

my $boo = MyCache->boo('boo');
my $boo2 = MyCache->boo('boo2');

like ( $boo , qr/^\d+boo$/ , "get boo('boo') ok : $boo " );
like ( $boo2 , qr/^\d+boo2$/ , "get boo('boo2') ok : $boo2 " );
sleep 1;
MyCache->delete( 'boo' , 'boo' );
ok( $boo ne MyCache->boo('boo') , 'delete boo boo' );
ok( $boo2 eq MyCache->boo('boo2') , 'not delete boo boo2' . "[$boo2]:[" .  MyCache->boo('boo2') . "]");




diag( "Testing Cache::Funky $Cache::Funky::VERSION" );


