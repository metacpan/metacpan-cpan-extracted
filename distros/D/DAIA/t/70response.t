use strict;
use Test::More;
use DAIA;

ok( DAIA::is_uri("my:foo"), 'is_uri (1)' );
ok( !DAIA::is_uri("123"), 'is_uri (0)' );

my $daia = response;
isa_ok( $daia, 'DAIA::Response' );

my $d1 = response( $daia );
is_deeply( $d1, $daia, 'copy constructor' );

is( $daia->version, '0.5' );
ok( $daia->timestamp, 'timestamp initialized' );

my $doc = document( id => 'my:123' );
$daia->document( $doc );
is_deeply( $daia->document, $doc );

my $inst = institution( 'foo' );
$daia->institution( $inst );
is_deeply( $daia->institution, $inst );

done_testing;
