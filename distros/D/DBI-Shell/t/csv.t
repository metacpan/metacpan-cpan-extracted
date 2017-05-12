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

		require Text::Reform;
	};
	if ($@) {
		# warn "Text::Reform is not installed, skipping tests";
		print "1..0 ";
		warn " Text::Reform not installed\n";
		exit;
	}
}

my $LOAD_SQL=q{testsqlminus.sql};
my $SAVE_SQL=q{testsql.tmp};


use Test::More tests => 13;

BEGIN { use_ok( 'DBI::Shell' ); }

	require_ok( 'Text::Reform' );

$ENV{DBISH_CONFIG} = qq{dbish_config};

ok (exists $ENV{DBISH_CONFIG}, "Testing CSV plugin for dbish. Configuration file dbish_config." );

$sh = DBI::Shell->new(qw(dbi:ExampleP:));
ok(defined $sh, "Create statement handler" );

ok( ! $sh->do_connect( qw(dbi:ExampleP:)), "Connecting to source" );


ok( $sh->do_format( q{csv} ), "Change format to csv" );

# nlink,ino,blocks,ctime,rdev,mtime,mode,blksize,gid,size,dev,name,atime,uid

ok( ! $sh->do_load( $LOAD_SQL ));
ok( ! $sh->do_go );

ok(   $sh->do_option( "sep=^" ));
ok( ! $sh->do_go );

ok(   $sh->do_option( "sep=|" ));
ok( ! $sh->do_go );

ok( ! $sh->do_disconnect, "Disconnect from source." );
$sh = undef;

END { unlink $SAVE_SQL if -f $SAVE_SQL }

__END__
