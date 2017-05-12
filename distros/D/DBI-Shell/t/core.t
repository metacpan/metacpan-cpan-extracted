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

use Test::More tests => 9;

BEGIN { use_ok( 'DBI::Shell' ); }

use DBI;
use DBI::Shell;

my $sh = DBI::Shell::Std->new(qw(dbi:ExampleP:));
ok(defined $sh, "Create Std handler");

my $con = q{dbi:ExampleP:};
ok( ! $sh->do_connect( $con ), "Connect to $con");

ok( ! $sh->do_disconnect, "Disconnect from $con" );

pass( "Creating second handler" );

my $th = DBI::Shell::Std->new($con);
ok( defined $th, "Connect second $con" );

ok( ! $th->do_connect( $con), "Connect again.");
ok( ! $th->do_connect( $con), "Connect again.");

ok( ! $th->do_disconnect, "Disconnect second $con");

undef $sh; undef $th;

END { }

__END__
