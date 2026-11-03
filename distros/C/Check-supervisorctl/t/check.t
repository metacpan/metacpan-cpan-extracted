#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Check::supervisorctl;

my $status = <<'EOF';
foo                              RUNNING   pid 123, uptime 1 day, 0:00:01
bar                              STARTING
grp:baz                          RUNNING   pid 124, uptime 1 day, 0:00:01
EOF

# all running or starting is OK
my $results = Check::supervisorctl->new->run( status_output => $status );
is( $results->{exit},  0, 'running and starting is OK' );
is( $results->{total}, 3, 'total' );
is_deeply( $results->{status_list}{running}, [ 'foo', 'grp:baz' ], 'status_list running' );
is( $results->{status}{bar}, 'starting', 'status' );
is_deeply( $results->{status_errors}, [], 'no status errors' );

# fatal is ALERT
$results = Check::supervisorctl->new->run( status_output => $status . "qux FATAL Exited too quickly\n" );
is( $results->{exit}, 2, 'fatal is 2' );
ok( ( grep { $_ eq 'ALERT - qux, fatal' } @{ $results->{results} } ), 'fatal result line' );

# remapping it
$results = Check::supervisorctl->new( status_mapping => { FATAL => 1 } )
	->run( status_output => $status . "qux FATAL Exited too quickly\n" );
is( $results->{exit}, 1, 'fatal remapped to 1' );

# ignoring it
$results = Check::supervisorctl->new( ignore => ['qux'] )->run( status_output => $status . "qux FATAL\n" );
is( $results->{exit}, 0, 'ignored fatal is OK' );
is_deeply( $results->{ignored}, ['qux'], 'ignored' );
ok( ( grep { $_ eq 'IGNORED - qux, fatal' } @{ $results->{results} } ), 'ignored result line' );
ok( !defined( $results->{status}{qux} ),                                'ignored not in status' );

# supervisord being down must not be OK
$results = Check::supervisorctl->new->run( status_output => "unix:///var/run/supervisor.sock no such file\n" );
is( $results->{exit},  3, 'supervisord down is UNKNOWN' );
is( $results->{total}, 0, 'nothing found' );
is_deeply(
	$results->{status_errors},
	['supervisorctl status returned "unix:///var/run/supervisor.sock no such file"'],
	'status error'
);
$results = Check::supervisorctl->new( status_error_val => 2 )->run( status_output => "garbage\n" );
is( $results->{exit}, 2, 'status_error_val' );

# config checking
my $dir = tempdir( CLEANUP => 1 );
foreach my $config ( 'foo', 'bar', 'notrunning', 'ignoredconf', 'qux' ) {
	open( my $fh, '>', $dir . '/' . $config . '.conf' ) or die($!);
	close($fh);
}
open( my $fh, '>', $dir . '/README' ) or die($!);
close($fh);
$results = Check::supervisorctl->new(
	config_check  => 1,
	config_dir    => $dir,
	config_ignore => ['ignoredconf'],
	ignore        => ['qux'],
)->run( status_output => $status . "qux FATAL\n" );
is( $results->{exit}, 2, 'config not running and config missing is 2' );
is_deeply( $results->{configs},            [ 'bar', 'foo', 'notrunning', 'qux' ], 'configs' );
is_deeply( $results->{config_ignored},     ['ignoredconf'],                       'config_ignored' );
is_deeply( $results->{config_not_running}, ['notrunning'], 'config_not_running, ignored items not' );
is_deeply( $results->{config_missing},     ['grp:baz'],    'config_missing' );

# config_missing_val is used for missing configs
$results = Check::supervisorctl->new(
	config_check       => 1,
	config_dir         => $dir,
	config_ignore      => [ 'ignoredconf', 'notrunning', 'qux' ],
	config_missing_val => 1,
)->run( status_output => $status );
is( $results->{exit}, 1, 'config_missing_val' );
ok( ( grep { $_ eq 'WARNING - missing config grp:baz' } @{ $results->{results} } ), 'missing config result line' );

# missing config dir
$results
	= Check::supervisorctl->new( config_check => 1, config_dir => $dir . '/nope' )->run( status_output => $status );
is( $results->{exit},               3, 'missing config dir is 3' );
is( $results->{config_dir_missing}, 1, 'config_dir_missing' );
ok( ( grep { /config dir.*missing/ } @{ $results->{results} } ), 'missing config dir result line' );

# parse_mappings
my %mapping_opts = Check::supervisorctl->parse_mappings( ' Stopped = 1 ', 'config_missing=0', 'status_error=2' );
is_deeply( \%mapping_opts, { status_mapping => { stopped => 1 }, config_missing_val => 0, status_error_val => 2 },
	'parse_mappings' );
ok( !eval { Check::supervisorctl->parse_mappings('stopped');    1 }, 'parse_mappings dies on no =' );
ok( !eval { Check::supervisorctl->parse_mappings('bogus=1');    1 }, 'parse_mappings dies on unknown name' );
ok( !eval { Check::supervisorctl->new( status_error_val => 4 ); 1 }, 'new dies on a bad value' );

done_testing();
