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

use Test::More tests => 51;

BEGIN { use_ok( 'DBI::Shell' ); }

my $LOAD_SQL=q{testsql.sql};
my $SAVE_SQL=q{testsql.tmp};

my $sh = DBI::Shell->new(qw(dbi:ExampleP:));
ok(defined $sh, "Create new handler");

ok( ! $sh->do_connect( qw(dbi:ExampleP:)), "Connect to source");

ok( ! $sh->do_drivers(), "Do drivers" );

ok( ! $sh->do_table_info(), "Do table_info");

ok( ! $sh->do_type_info(), "Do type_info" );

ok( ! $sh->do_clear(), "Do clear" );

ok( ! $sh->do_rhistory, "Recall results history" );

ok( ! $sh->do_chistory, "Recall command history" );

ok( ! $sh->do_history, "Recall history" );

ok( ! $sh->do_help, "Help ..." );

ok( ! $sh->do_option, "Options ... " );

ok( -f $LOAD_SQL, "Have test file?" );

ok( ! $sh->do_load( $LOAD_SQL ), "Loading test file $LOAD_SQL" );

ok( ! $sh->do_go, "Execute current buffer" );

ok( $sh->do_get, "Get last command executed" );

ok( ! $sh->do_go, "Execute current buffer" );

ok( $sh->do_get(1), "Get first command executed" );

ok( ! $sh->do_go, "Execute current buffer" );

unlink $SAVE_SQL if -f $SAVE_SQL;

ok( ! $sh->do_save( $SAVE_SQL ), "Save current buffer to file $SAVE_SQL" );

ok( -f $SAVE_SQL, "Does $SAVE_SQL exists?" );

unlink $SAVE_SQL if -f $SAVE_SQL;

# ok( $sh->do_disconnect, "Disconnect from source" );
# undef $sh;

$ENV{DBISH_CONFIG} = qq{dbish_config};

ok ( exists $ENV{DBISH_CONFIG}, "Configuration file defined in environment" );

# $sh = DBI::Shell->new(qw(dbi:ExampleP:));
# ok(defined $sh, "Create shell handler" );

# Testing basic connect, load, and execute.
ok( ! $sh->do_connect( qw(dbi:ExampleP:)), "Connect to source" );
ok( ! $sh->do_load( $LOAD_SQL ), "Load current buffer from $LOAD_SQL" );
ok( ! $sh->do_go, "Execute current buffer" );

ok( ! $sh->do_commit, "Do commit" );
ok( ! $sh->do_rollback, "Do rollback" );

# Test different display formats.

foreach my $format (qw{neat box string html raw neat} ) {
	ok( $sh->do_format( $format ), "Set format to $format");
	ok( $sh->do_get, "Last executed command" );
	ok( ! $sh->do_go, "Execute current buffer" );
}

ok( $sh->do_format( 'neat' ), "Set format to neat");

# Test negative numbers with get
ok( $sh->do_get(-1), "Get with -1 command" );
ok( ! $sh->do_go, "Execute current buffer" );

ok( $sh->do_get(-2), "Get with -2 command" );
ok( ! $sh->do_go, "Execute current buffer" );

ok( ! $sh->do_disconnect, "Disconnect" );

$sh = undef;

END { 
	unlink $SAVE_SQL if -f $SAVE_SQL;
	}

__END__
