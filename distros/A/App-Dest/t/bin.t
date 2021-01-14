use Test2::V0;
use File::Basename 'dirname';
use IPC::Run 'run';

chdir( dirname($0) . '/../bin' );
my ( $out, $err );
my @dest = ( $^X, '-I../lib', 'dest' );

run( [ @dest, 'help' ], \undef, \$out, \$err );
like( $out, qr/Usage:\s+dest COMMAND \[OPTIONS\]/, 'help' );

run( [ @dest, 'version' ], \undef, \$out, \$err );
like( $out, qr/^dest version [\d\.]+$/, 'version' );

done_testing;
