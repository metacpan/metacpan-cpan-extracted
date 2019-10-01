use Test::Most;
use File::Basename 'dirname';
use IPC::Run 'run';

chdir( dirname($0) . '/../bin' );
my ( $out, $err );

run( [ qw( /usr/bin/env perl dest help ) ], \undef, \$out, \$err );
like( $out, qr/Usage:\s+dest COMMAND \[OPTIONS\]/, 'help' );

run( [ qw( /usr/bin/env perl dest version ) ], \undef, \$out, \$err );
like( $out, qr/^dest version [\d\.]+$/, 'version' );

done_testing();
