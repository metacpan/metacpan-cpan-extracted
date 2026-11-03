#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON       qw(encode_json);
use POSIX      qw(strftime);

# Monitoring::Sneck::Checks is optional, the check is of no use without it
if ( !eval { require Monitoring::Sneck::Checks; 1 } ) {
	plan( skip_all => 'Monitoring::Sneck::Checks not installed' );
}

my $dir = tempdir( CLEANUP => 1 );

# writes a flow file, each flow being [ host, src_ip, pkts_toserver, pkts_toclient ], with a host of undef
# leaving .host out, all $age seconds old
my $age        = 0;
my $file_count = 0;
my $flows      = sub {
	my (@flows) = @_;

	my $when = strftime( '%Y-%m-%dT%H:%M:%S.123456+0000', gmtime( time - $age ) );
	my $file = $dir . '/flow' . $file_count++ . '.json';
	open( my $fh, '>', $file ) or die($!);
	foreach my $flow (@flows) {
		my %entry = (
			timestamp  => $when,
			event_type => 'flow',
			src_ip     => $flow->[1],
			dest_ip    => '198.51.100.10',
			flow       => { pkts_toserver => $flow->[2], pkts_toclient => $flow->[3] },
		);
		$entry{host} = $flow->[0] if defined( $flow->[0] );
		print $fh encode_json( \%entry ) . "\n";
	}
	close($fh);

	return $file;
};
my $bi  = sub { my ( $count, $host, $ip ) = @_; return map { [ $host, $ip // '192.0.2.20', 5, 7 ] } 1 .. $count };
my $uni = sub { my ( $count, $host ) = @_; return map { [ $host, '192.0.2.20', 5, 0 ] } 1 .. $count };
my $run = sub {
	return Monitoring::Sneck::Checks->run( check => 'suricata_flows', args => [@_] );
};

# the defaults, 20 or under is WARNING and 10 or under CRITICAL
my $file   = $flows->( $bi->( 25, 's1' ), $uni->( 3, 's1' ) );
my $return = $run->( '-f', $file );
is( $return->{code}, 0, '25 bi directional is OK' ) or diag( $return->{combined} );
my @lines = split( /\n/, $return->{stdout} );
is(
	$lines[0],
	'SURICATA_FLOWS OK - 25 bi directional, 3 uni directional flows | bi=25;21:;11:;0 uni=3;;;0',
	'status line'
);
is( $lines[1], 'OK: bi directional count of 25', 'the same lines as check_suricataflows follow' );
like( $return->{stdout}, qr/^seen sensors: s1$/m, 'seen sensors' );
like( $return->{stdout}, qr/^lines read: 28$/m,   'lines read' );
is( $return->{stderr}, '', 'nothing on stderr' );

is( $run->( '-f', $flows->( $bi->( 21, 's1' ) ) )->{code}, 0, '21 bi directional is OK' );
is( $run->( '-f', $flows->( $bi->( 20, 's1' ) ) )->{code}, 1, '20 bi directional is WARNING' );
is( $run->( '-f', $flows->( $bi->( 11, 's1' ) ) )->{code}, 1, '11 bi directional is WARNING' );
is( $run->( '-f', $flows->( $bi->( 10, 's1' ) ) )->{code}, 2, '10 bi directional is CRITICAL' );
is( $run->( '-f', $flows->( $uni->( 50, 's1' ) ) )->{code}, 2, 'only uni directional is CRITICAL' );
$return = $run->( '-f', $flows->( $bi->( 15, 's1' ) ), '-w', '5', '-a', '2' );
is( $return->{code}, 0, '-w and -a are used' );
like( $return->{stdout}, qr/ \| bi=15;6:;3:;0 /, '-w and -a in perfdata' );

# -m
$return = $run->( '-f', $flows->( $bi->( 25, 's1' ) ), '-m', '5' );
is( $return->{code}, 2, '-m limits the lines read' );
like( $return->{stdout}, qr/^max lines to read: 5$/m, '-m shown' );

# -t, how far back to read
$age  = 120;
$file = $flows->( $bi->( 25, 's1' ) );
$age  = 0;
is( $run->( '-f', $file )->{code},              0, 'flows two minutes old are read by default' );
is( $run->( '-f', $file, '-t', '60' )->{code}, 2, '-t 60 does not read flows two minutes old' );

# per sensor
$file   = $flows->( $bi->( 25, 's1' ), $bi->( 15, 's2' ) );
$return = $run->( '-f', $file, '-s', 's1', '-s', 's2' );
is( $return->{code}, 1, 'a sensor under the warning is WARNING, though the total is OK' ) or diag( $return->{combined} );
like( $return->{stdout}, qr/ \| bi=40;21:;11:;0 uni=0;;;0 bi_s1=25;21:;11:;0 bi_s2=15;21:;11:;0$/m, 'per sensor perfdata' );
like( $return->{stdout}, qr/^OK, s1: bi directional count of 25$/m,                     's1' );
like( $return->{stdout}, qr/^WARN, s2: bi directional count of 15 is less than 20$/m, 's2' );
$return = $run->( '-f', $file, '-s', 's1', '-s', 's3' );
is( $return->{code}, 2, 'a sensor never seen is CRITICAL' );
like( $return->{stdout}, qr/^ALERT, s3: sensor never seen$/m, 's3' );
like( $return->{stdout}, qr/ bi_s3=0;21:;11:;0$/m,          's3 perfdata' );

# ignoring IPs
$file   = $flows->( $bi->( 25, 's1', '192.0.2.1' ), $bi->( 5, 's1' ) );
$return = $run->( '-f', $file, '-i', '192.0.2.1' );
is( $return->{code}, 2, 'ignored flows are not counted' );
like( $return->{stdout}, qr/^ignored IPs: 192\.0\.2\.1$/m, 'ignored IPs listed' );

# flows without .host must not warn, as that would end up in sneck's output
$return = $run->( '-f', $flows->( $bi->( 25, undef ) ) );
is( $return->{code},   0,  'flows without .host' );
is( $return->{stderr}, '', 'flows without .host do not warn' );

# problems are UNKNOWN
$return = $run->( '-f', $dir . '/not-there.json' );
is( $return->{code}, 3, 'a missing file is UNKNOWN' );
like( $return->{stdout}, qr/^SURICATA_FLOWS UNKNOWN - flow file, '[^']+not-there\.json', does not exist$/, 'missing file' );
$return = $run->( '-f', $file, '-i', 'not an IP' );
is( $return->{code}, 3, 'a bad IP to ignore is UNKNOWN' );
like( $return->{stderr}, qr/does not appear to be IPv4 or IPv6/, 'why' );
is( $run->( '-f', $file, '-w', 'bogus' )->{code}, 3, 'a bad warn count is UNKNOWN' );
is( $run->( '-f', $file, '-t', 'x' )->{code},     3, 'a bad -t is UNKNOWN' );

done_testing();
