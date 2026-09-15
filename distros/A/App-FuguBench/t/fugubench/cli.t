#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The shared contract of the program: the two channels, the exit
# codes, the help, and the verb that reads no checkout.
#
# Each case runs bin/fugubench as a child with -Ilib, so the test
# sees the process as a hook does. Every later verb inherits these
# assertions.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::Process;

use App::FuguBench;
use App::FuguBench::Checkout;

my $root    = "$RealBin/../..";
my $program = "$root/bin/fugubench";

# The version of the loaded module: none in a checkout, and the stamp
# of the dist build in a staged distribution. The child loads the
# same file, so a literal here would hold in a checkout alone.
my $version = App::FuguBench->VERSION // '0.0.0';

# _run($dir, @argv):
#	Run the program as a child in one directory, and return the
#	result of Fugu::Process->run.
sub _run ( $dir, @argv )
{
	my $result = Fugu::Process->run(
		cmd => [ $^X, "-I$root/lib", $program, @argv ],
		cwd => $dir,
	);
	die "cannot run $program: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# The help goes to standard output, because the user asked for it
{
	my $r = _run( $root, '--help' );
	is( $r->{exit_code}, 0, '--help exits 0' );
	like( $r->{stdout}, qr/^usage: fugubench /m, '--help prints usage' );
	like(
		$r->{stdout}, qr/^\s+version\s/m,
		'--help lists the version verb'
	);
	is( $r->{stderr}, '', '--help writes nothing to standard error' );
}

{
	my $r = _run( $root, 'version', '--help' );
	is( $r->{exit_code}, 0, 'version --help exits 0' );
	like(
		$r->{stdout}, qr/^usage: fugubench version/m,
		'version --help prints the usage of the verb'
	);
	is(
		$r->{stderr}, '',
		'version --help writes nothing to standard error'
	);
}

# -h and the word help ask for the same help
{
	for my $form ( '-h', 'help' ) {
		my $r = _run( $root, $form );
		is( $r->{exit_code}, 0, "$form exits 0" );
		like(
			$r->{stdout}, qr/^usage: fugubench /m,
			"$form prints the usage to standard output"
		);
		is(
			$r->{stderr}, '',
			"$form writes nothing to standard error"
		);
	}
}

# A usage error goes to standard error with exit 2 (CLI-PROGRAM-3)
{
	my %case = (
		'an unknown verb'             => ['nosuchverb'],
		'a bad option'                => ['--nosuchoption'],
		'no verb'                     => [],
		'a global flag with no verb'  => ['--verbose'],
		'a global value with no verb' => [ '-C', $root ],
		'a bare double dash'          => ['--'],
	);
	for my $name ( sort keys %case ) {
		my $r = _run( $root, @{ $case{$name} } );
		is( $r->{exit_code}, 2, "$name exits 2" );
		like(
			$r->{stderr}, qr/^usage: fugubench /m,
			"$name prints the usage to standard error"
		);
		is(
			$r->{stdout}, '',
			"$name writes nothing to standard output"
		);
	}
}

# The result line of the version verb, and the silent channel beside
# it (CLI-PROGRAM-4, DIST-VERSION-1)
{
	my $r = _run( $root, 'version' );
	is( $r->{exit_code}, 0, 'version exits 0' );
	like(
		$r->{stdout},
		qr/\A fugubench \s \Q$version\E \s [(] Fugu \s [^)]+ [)] \n \z/x,
		'version prints one line with both versions'
	);
	is( $r->{stderr}, '', 'version writes nothing to standard error' );
}

# A verb runs with a global option in front of it (CLI-PROGRAM-2)
{
	my %case = (
		'--verbose' => ['--verbose'],
		'-C <dir>'  => [ '-C', $root ],
	);
	for my $name ( sort keys %case ) {
		my $r = _run( $root, @{ $case{$name} }, 'version' );
		is( $r->{exit_code}, 0, "$name version exits 0" );
		like(
			$r->{stdout}, qr/\Afugubench \Q$version\E /,
			"$name version prints the version line"
		);
		is(
			$r->{stderr}, '',
			"$name version writes nothing to standard error"
		);
	}
}

# The walk runs on demand, so a verb that reads no checkout runs in a
# home with no .toolingrc (CLI-CHECKOUT-5)
{
	my $dir = tempdir( CLEANUP => 1 );
	ok(
		!defined App::FuguBench::Checkout->new( start => $dir ),
		'the temporary tree sits under no checkout'
	);

	my $r = _run( $dir, 'version' );
	is( $r->{exit_code}, 0, 'version exits 0 without a .toolingrc' );
	like(
		$r->{stdout}, qr/\Afugubench /,
		'version prints its line without a .toolingrc'
	);
}

done_testing();
