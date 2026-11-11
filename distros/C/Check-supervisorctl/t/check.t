#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Check::supervisorctl;

# temp stuff goes in t/tmp/ and not /tmp, as /tmp may be noexec, which would break the fake supervisorctl
mkdir("t/tmp");

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
my $dir = tempdir( DIR => "t/tmp", CLEANUP => 1 );
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

# restarting, with a fake command that records what it was asked to do and
# fails for anything named broken
my @commands;
my $fake_command = sub {
	push( @commands, join( ' ', @_ ) );
	if ( defined( $_[1] ) && $_[1] eq 'broken' ) {
		return ( 0, $_[1] . ": ERROR (spawn error)\n" );
	}
	return ( 0, "ok\n" );
};
my $not_running = <<'EOF';
foo      RUNNING   pid 123, uptime 1 day, 0:00:01
stopme   STOPPED   Nov 10 01:00 PM
exitme   EXITED    Nov 10 01:00 PM
fatalme  FATAL     Exited too quickly
backme   BACKOFF   Exited too quickly
stopping STOPPING
broken   FATAL     Exited too quickly
qux      FATAL     Exited too quickly
EOF
$results = Check::supervisorctl->new( ignore => ['qux'] )->run( status_output => $not_running );
is( $results->{exit}, 2, 'not running is 2 without restart' );
is_deeply( $results->{restarted}, [], 'nothing restarted without restart' );

$results = Check::supervisorctl->new( restart => 1, ignore => ['qux'] )
	->run( status_output => $not_running, command => $fake_command );
is( $results->{exit}, 2, 'restarting does not change the exit' );
is_deeply(
	\@commands,
	[ 'restart backme', 'start broken', 'start exitme', 'start fatalme', 'start stopme' ],
	'start for stopped, exited, and fatal, restart for backoff, nothing for ignored or stopping'
);
is_deeply( $results->{restarted},      [ 'backme', 'exitme', 'fatalme', 'stopme' ], 'restarted' );
is_deeply( $results->{restart_failed}, ['broken'],                                  'restart_failed' );
ok( ( grep { $_ eq 'RESTARTED - stopme, stopped' } @{ $results->{results} } ), 'restarted result line' );
ok( ( grep { $_ eq 'RESTART FAILED - broken, fatal: broken: ERROR (spawn error)' } @{ $results->{results} } ),
	'restart failed result line' );

# a failed restart does not raise the exit either
@commands = ();
$results  = Check::supervisorctl->new( restart => 1, status_mapping => { fatal => 0 } )
	->run( status_output => "broken FATAL\n", command => $fake_command );
is( $results->{exit}, 0, 'a failed restart does not raise the exit' );
is_deeply( $results->{restart_failed}, ['broken'], 'restart_failed with a 0 mapping' );

# a non-zero exit is a failure as well
$results = Check::supervisorctl->new( restart => 1 )
	->run( status_output => "stopme STOPPED\n", command => sub { return ( 7, "nope\n" ) } );
is_deeply( $results->{restart_failed}, ['stopme'], 'non-zero exit is a failed restart' );

# adding configs
@commands = ();
my %add_opts = (
	config_check  => 1,
	config_dir    => $dir,
	config_ignore => ['ignoredconf'],
	ignore        => ['qux'],
	add_configs   => 1,
);
$results
	= Check::supervisorctl->new(%add_opts)->run( status_output => $status . "qux FATAL\n", command => $fake_command );
is( $results->{exit}, 2, 'adding does not change the exit' );
is_deeply( \@commands,        [ 'reread', 'add notrunning' ], 'reread then add, nothing for ignored configs or items' );
is_deeply( $results->{added}, ['notrunning'],                 'added' );
ok( ( grep { $_ eq 'ADDED - config notrunning' } @{ $results->{results} } ), 'added result line' );

# a failed reread fails all the adds
@commands = ();
$results  = Check::supervisorctl->new(%add_opts)->run(
	status_output => $status . "qux FATAL\n",
	command       => sub { push( @commands, join( ' ', @_ ) ); return ( 2, "ERROR: bad config\n" ) }
);
is_deeply( \@commands,             ['reread'],     'no adds if reread failed' );
is_deeply( $results->{add_failed}, ['notrunning'], 'add_failed if reread failed' );
ok(
	( grep { $_ eq 'ADD FAILED - config notrunning: reread failed: ERROR: bad config' } @{ $results->{results} } ),
	'reread failed result line'
);

# nothing to add means no reread
@commands = ();
Check::supervisorctl->new( %add_opts, config_ignore => [ 'ignoredconf', 'notrunning' ] )
	->run( status_output => $status . "qux FATAL\n", command => $fake_command );
is_deeply( \@commands, [], 'no reread if nothing to add' );

ok( !eval { Check::supervisorctl->new( add_configs => 1 ); 1 }, 'add_configs requires config_check' );

# the default command, via a fake supervisorctl in the path
my $bin_dir = tempdir( DIR => "t/tmp", CLEANUP => 1 );
open( my $fake_fh, '>', $bin_dir . '/supervisorctl' ) or die($!);
print $fake_fh "#!/bin/sh\necho \"\$1 \$2\"\necho oops >&2\n";
close($fake_fh);
chmod( 0755, $bin_dir . '/supervisorctl' );
SKIP: {
	# only the fake in the path, so a real supervisorctl is never ran in its place
	local $ENV{PATH} = $bin_dir;
	skip( "can not execute the fake supervisorctl in $bin_dir", 2 ) if !defined( `$bin_dir/supervisorctl 2> /dev/null` ) || $? != 0;
	is_deeply(
		[ Check::supervisorctl::_run_supervisorctl( 'start', 'a b;c' ) ],
		[ 0, "start a b;c\noops\n" ],
		'default command, no shell, stderr included'
	);
	$results = Check::supervisorctl->new( restart => 1 )->run( status_output => "stopme STOPPED\n" );
	is_deeply( $results->{restarted}, ['stopme'], 'restart via the default command' );
}
{
	local $ENV{PATH} = $bin_dir . '/nope';
	my ( $exit, $output ) = Check::supervisorctl::_run_supervisorctl('reread');
	is( $exit, 127, 'not being able to run supervisorctl is 127' );
	like( $output, qr/^can not run supervisorctl/, 'why it could not be ran' );
}

# parse_mappings
my %mapping_opts = Check::supervisorctl->parse_mappings( ' Stopped = 1 ', 'config_missing=0', 'status_error=2' );
is_deeply( \%mapping_opts, { status_mapping => { stopped => 1 }, config_missing_val => 0, status_error_val => 2 },
	'parse_mappings' );
ok( !eval { Check::supervisorctl->parse_mappings('stopped');    1 }, 'parse_mappings dies on no =' );
ok( !eval { Check::supervisorctl->parse_mappings('bogus=1');    1 }, 'parse_mappings dies on unknown name' );
ok( !eval { Check::supervisorctl->new( status_error_val => 4 ); 1 }, 'new dies on a bad value' );

done_testing();
