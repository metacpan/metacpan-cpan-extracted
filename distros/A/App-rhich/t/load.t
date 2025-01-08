use Test::More;

my $compile = `$^X -c blib/script/rhich 2>&1`;
diag( "Compiler says [$compile]" );
like( $compile, qr/OK/, 'rhich compiled OK' );

done_testing();
