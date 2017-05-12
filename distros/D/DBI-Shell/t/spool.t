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

	eval {
		require IO::Tee;
	};
	if ($@) {
		print "1..0 ";
		warn " IO::Tee not installed\n";
		exit;
	}
}

my $LOAD_SQL=q{testsqlminus.sql};
my $SAVE_SQL=q{testsql.tmp};
my $SPOOL_FILE=q{testspool.tmp};


use Test::More tests => 14;

BEGIN { use_ok( 'DBI::Shell' ); }

$ENV{DBISH_CONFIG} = qq{dbish_config};

ok (exists $ENV{DBISH_CONFIG}, "Testing Spool plugin for dbish. Configuration file dbish_config." );

$sh = DBI::Shell->new(qw(dbi:ExampleP:));
ok(defined $sh, "Create statement handler" );

ok( ! $sh->do_connect( qw(dbi:ExampleP:)), "Connecting to source" );

ok( ! $sh->do_load( $LOAD_SQL ));
ok( ! $sh->do_go );

unlink $SPOOL_FILE if -f $SPOOL_FILE;

ok( $sh->do_spool( $SPOOL_FILE ), "Spooling $SPOOL_FILE" );
ok( $sh->do_spool( ), "Spooling to $SPOOL_FILE" );
ok( $sh->do_get(), "Get command" );

ok( ! $sh->do_go, "Execute current buffer" );

ok( $sh->do_spool( q{off} ), "Spool off" );
ok( $sh->do_spool( ), "Spool is off" );

ok(  -f $SPOOL_FILE, "Created Spool file" );

ok( ! $sh->do_disconnect, "Disconnect" );

$sh = undef;

END { 
	unlink $SAVE_SQL if -f $SAVE_SQL;
	unlink $SPOOL_FILE if -f $SPOOL_FILE;
	}

__END__
