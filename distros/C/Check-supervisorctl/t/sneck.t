#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Monitoring::Sneck::Checks is optional, the check is of no use without it
if ( !eval { require Monitoring::Sneck::Checks; 1 } ) {
	plan( skip_all => 'Monitoring::Sneck::Checks not installed' );
}

my $dir = tempdir( CLEANUP => 1 );

# writes a fake supervisorctl that prints the given output and exits with the given code
my $fake_count = 0;
my $fake       = sub {
	my ( $output, $exit ) = @_;
	my $out_file = $dir . '/output' . $fake_count;
	open( my $out_fh, '>', $out_file ) or die($!);
	print $out_fh $output;
	close($out_fh);
	my $script = $dir . '/supervisorctl' . $fake_count++;
	open( my $fh, '>', $script ) or die($!);
	print $fh "#!/bin/sh\ncat '" . $out_file . "'\nexit " . ( $exit // 0 ) . "\n";
	close($fh);
	chmod( 0755, $script );
	return $script;
}; ## end $fake = sub
my $run = sub {
	return Monitoring::Sneck::Checks->run( check => 'supervisorctl', args => [@_] );
};

my $status = <<'EOF';
foo                              RUNNING   pid 123, uptime 1 day, 0:00:01
bar                              STARTING
EOF

my $return = $run->( '-p', $fake->($status) );
is( $return->{code}, 0, 'running and starting is OK' ) or diag( $return->{combined} );
my @lines = split( /\n/, $return->{stdout} );
is(
	$lines[0],
	'SUPERVISORCTL OK - 1 running, 1 starting | running=1;;;0 starting=1;;;0 backoff=0;;;0 stopping=0;;;0 '
		. 'stopped=0;;;0 exited=0;;;0 fatal=0;;;0 unknown=0;;;0 ignored=0;;;0',
	'status line'
);
is( $lines[1],         'OK - foo, running', 'the same lines as check_supervisorctl follow' );
is( $return->{stderr}, '',                  'nothing on stderr' );

# not running items, with supervisorctl exiting non-zero as it does then
$return = $run->( '-p', $fake->( $status . "qux FATAL Exited too quickly\n", 3 ) );
is( $return->{code}, 2, 'fatal is CRITICAL' );
like( $return->{stdout}, qr/^SUPERVISORCTL CRITICAL - 1 running, 1 starting, 1 fatal \|/, 'fatal status line' );
like( $return->{stdout}, qr/^ALERT - qux, fatal$/m,                                       'fatal line' );
is( $run->( '-p', $fake->( $status . "qux FATAL\n", 3 ), '-s', 'fatal=1' )->{code}, 1, '-s' );
$return = $run->( '-p', $fake->( $status . "qux FATAL\n", 3 ), '-i', 'qux' );
is( $return->{code}, 0, '-i' );
like( $return->{stdout}, qr/ ignored=1;;;0$/m, 'ignored perfdata' );

# supervisord down
$return = $run->( '-p', $fake->( "unix:///var/run/supervisor.sock no such file\n", 4 ) );
is( $return->{code}, 3, 'supervisord down is UNKNOWN' );
like(
	$return->{stdout},
	qr/^SUPERVISORCTL UNKNOWN - supervisorctl status returned "unix:\/\/\/var\/run\/supervisor.sock no such file" \|/,
	'supervisord down status line'
);
is( $run->( '-p', $fake->( "", 0 ) )->{code}, 0, 'no items is OK' );
like( $run->( '-p', $fake->( "", 0 ) )->{stdout}, qr/^SUPERVISORCTL OK - no items \|/, 'no items' );

# config checking
my $conf_dir = $dir . '/conf.d';
mkdir($conf_dir) or die($!);
foreach my $config ( 'foo', 'bar', 'notrunning' ) {
	open( my $fh, '>', $conf_dir . '/' . $config . '.conf' ) or die($!);
	close($fh);
}
$return = $run->( '-p', $fake->( $status . "baz RUNNING\n" ), '-c', '-f', $conf_dir );
is( $return->{code}, 2, 'config not running and missing config is CRITICAL' );
like(
	$return->{stdout},
	qr/^SUPERVISORCTL CRITICAL - 2 running, 1 starting, 1 config not running, 1 missing config \|.* config_not_running=1;;;0 config_missing=1;;;0$/m,
	'config status line'
);
is( $run->( '-p', $fake->($status), '-c', '-f', $conf_dir, '-d', 'notrunning' )->{code}, 0, '-d' );
$return = $run->( '-p', $fake->($status), '-c', '-f', $dir . '/nope' );
is( $return->{code}, 3, 'missing config dir is UNKNOWN' );
like(
	$return->{stdout},
	qr/^SUPERVISORCTL UNKNOWN - 1 running, 1 starting, config dir missing \|/,
	'missing config dir'
);

# problems are UNKNOWN
$return = $run->( '-p', $dir . '/not-there' );
is( $return->{code}, 3, 'supervisorctl not being there is UNKNOWN' );
like( $return->{combined}, qr/can not run/, 'why' );
is( $run->( '-p', $fake->($status), '-s', 'bogus=1' )->{code}, 3, 'a bad -s name is UNKNOWN' );
is( $run->( '-p', $fake->($status), '-s', 'fatal=9' )->{code}, 3, 'a bad -s value is UNKNOWN' );
is( $run->( '-p', $fake->($status), '-x' )->{code}, 3, 'a unknown option is UNKNOWN' );

done_testing();
