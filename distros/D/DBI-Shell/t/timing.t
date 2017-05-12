#!../../perl -w

$|=1;

BEGIN {
	require Getopt::Long;

	if ($Getopt::Long::VERSION && $Getopt::Long::VERSION < 2.17) {
		print "# DBI::Shell needs Getopt::Long version 2.17 or later\n";
		print "1..0\n";
		exit 0;
	}

	# keep dumb Term::ReadKey happy
	$ENV{COLUMNS} = 80;
	$ENV{LINES} = 24;
	{
		local ($^W) = 0;
		delete $ENV{DBI_DSN};
		delete $ENV{DBI_USER};
		delete $ENV{DBI_PASS};
		delete $ENV{DBISH_CONFIG};
	}
}

my $LOAD_SQL=q{testtiming.sql};
my $SAVE_SQL=q{testtiming.tmp};

use Test::More tests => 77;

BEGIN { use_ok( 'DBI::Shell' ); }

#print "begin testing DBISH_CONFIG file\n";
$ENV{DBISH_CONFIG} = qq{dbish_config};

my $sh = DBI::Shell->new(qw(dbi:ExampleP:));
ok(defined $sh, "Create shell instance" );

#print "load plugins\n";
#ok( $sh->load_plugins, "Loading plugins" );;

#print "do connect\n";
ok( ! $sh->do_connect( qw(dbi:ExampleP:)),
	"Connecting to dbi:ExampleP:");

#print "load test file $LOAD_SQL\n";
ok( ! $sh->do_load( $LOAD_SQL ), "Loading test file: $LOAD_SQL");

#print "execute\n";
ok( ! $sh->do_go, "Execute loaded statement" );

#print "timing\n";
ok( $sh->do_format( q{neat} ), "Change output format to neat");

ok( $sh->do_timing( q{off} ) == 0, "Turn timing OFF" );
ok( ($rv = $sh->do_timing)   == 0, "Timing is OFF" );
ok( $sh->do_get, "Get the last statement executed" );
ok(!$sh->do_go, "Execute statement in buffer" );

ok( $sh->do_timing( q{on} ) == 1, "Turn timing ON" );
ok( ($rv = $sh->do_timing)  == 1, "Timing is ON" );
ok( $sh->do_get, "Get the last statement executed" );
ok(!$sh->do_go, "Execute statement in buffer" );

ok( $sh->do_timing == 1, "Display timing status" );
ok( $sh->do_get, "Get the last statement executed" );
ok(!$sh->do_go, "Execute statement in buffer" );

my $rv = 0;
ok( $sh->do_option( 'timing_timing' )   == 1, "Check options: timing_timing" );
ok( $sh->do_option( 'timing_timing=1' ) == 1, "Check options: timing_timing=1" );

ok( $sh->do_option( 'timing_timing=0' ) == 0, "Check options: timing_timing=0" );
ok( ($rv = $sh->do_timing)     == 0, "Timing is OFF" );

ok( $sh->do_option( 'timing_timing=1' ) == 1, "Check options: timing_timing=1" );
ok( ($rv = $sh->do_timing)     == 1, "Timing is ON" );

ok( $sh->do_timing( q{off} )   == 0, "Turn timing OFF" );
ok( ($rv = $sh->do_timing)     == 0, "Test timing is OFF" );

ok( $sh->do_timing( q{on} )    == 1, "Turn timing ON" );
ok( ($rv = $sh->do_timing)     == 1, "Test timing is ON" );

ok( $sh->do_timing( q{stop} )  == 0, "Turn timing stop" );
ok( ($rv = $sh->do_timing)     == 0, "Test timing is OFF" );

ok( $sh->do_timing( q{start} ) == 1, "Turn timing start" );
ok( ($rv = $sh->do_timing)     == 1, "Test timing is ON" );

ok( $sh->do_timing( q{end} )   == 0, "Turn timing end" );
ok( ($rv = $sh->do_timing)     == 0, "Test timing is OFF" );

ok( $sh->do_timing( q{begin} ) == 1, "Turn timing begin" );
ok( ($rv = $sh->do_timing)     == 1, "Test timing is ON" );

ok( $sh->do_option( 'timing_style' ) eq 'auto' , "Current timing style options: timing_style" );
foreach my $style (qw(bad auto noc nop none all)) {
	ok( $sh->do_option( "timing_style=$style" ) eq $style, 
		"Current timing style options: timing_style=$style" );
	ok( $sh->do_get, "Get the last statement executed" );
	ok(!$sh->do_go, "Execute statement in buffer" );
}

# User may set any format, however invalid formats are silently
# ignored.
ok( $sh->do_option( 'timing_format' ) eq '5.2f' ,
	"Current timing format options: timing_format" );
foreach my $fmt (qw(5.2f 5.5f 5d 1s)) {
	ok( $sh->do_option( "timing_format=$fmt" ) eq $fmt, 
		"Current timing style options: timing_style=$fmt" );
	ok( $sh->do_get, "Get the last statement executed" );
	ok(!$sh->do_go, "Execute statement in buffer" );
}
ok( $sh->do_option( 'timing_format=5.2f' ) eq '5.2f', 
	"Resetting current timing_format=5.2f" );

ok( $sh->do_option( 'timing_prefix' ) eq 'Elapsed: ', 
	"Current timing prefix options: timing_prefix, Default" );

ok( $sh->do_option( 'timing_prefix="Timing: "' ) eq '"Timing: "', 
	'Current timing prefix options: timing_prefix="Timing: "' );

ok( $sh->do_option( 'timing_prefix=\"Timing: \"' ) eq '\"Timing: \"', 
	'Current timing prefix options: timing_prefix=\"Timing: \"' );

ok( $sh->do_option( "timing_prefix=\"Timing: \"" ) eq '"Timing: "', 
	"Current timing prefix options: timing_prefix=\"Timing: \"" );

ok( $sh->do_option( "timing_prefix=Timing:" ) eq 'Timing:', 
	"Current timing prefix options: timing_prefix=Timing:" );

ok( $sh->do_option( "timing_prefix=Timing: " ) eq 'Timing: ', 
	"Current timing prefix options: timing_prefix=Timing: " );

ok( $sh->do_option( "timing_prefix='undef'" ) eq q{'undef'},
	"Current timing prefix options: timing_prefix='undef'" );

ok( $sh->do_option( "timing_prefix" ) eq q{'undef'},
	"Current timing prefix options: timing_prefix, undefined" );

ok(!$sh->do_disconnect, "Disconnect from source." );

$sh = undef;

# print "unlinking $SAVE_SQL\n";


END { unlink $SAVE_SQL if -f $SAVE_SQL }

__END__
