#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Render: the probe, the lint, and the mandoc options.
#
# The test builds its sources in a File::Temp directory. It never reads
# the repository, so a change under man/ cannot break it.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use_ok('App::FuguWeb::Config');
use_ok('App::FuguWeb::Render');
use_ok('Fugu::Log');

# have($tool):
#	Report whether the program is on the path.
sub have ($tool)
{
	return system("command -v $tool >/dev/null 2>&1") == 0;
}

# quiet():
#	A logger that drops what a failing renderer reports. The test
#	asserts on the return value, not on the log.
sub quiet ()
{
	return Fugu::Log->new( mode => Fugu::Log::MODE_QUIET() );
}

# config($rc):
#	Load a description in a new temporary project.
sub config ( $rc = "site = Example\n" )
{
	my $root = tempdir( CLEANUP => 1 );
	open my $fh, '>', "$root/.fuguwebrc"
	    or die "Cannot write the description: $!";
	print {$fh} $rc;
	close $fh;

	my $loaded =
	    App::FuguWeb::Config->load( root => $root, error => \my $reason );
	die "$reason\n" unless $loaded;

	return $loaded;
}

subtest 'the probe names the first tool that is absent' => sub {
	my $render = App::FuguWeb::Render->new(
		config => config(),
		mandoc => '/nonexistent/mandoc',
	);
	is( $render->probe, '/nonexistent/mandoc',
		'an absent mandoc is reported by name' );

	$render = App::FuguWeb::Render->new(
		config  => config(),
		mandoc  => '/bin/sh',
		lowdown => '/nonexistent/lowdown',
		pod2man => '/bin/sh',
	);
	is( $render->probe, '/nonexistent/lowdown',
		'an absent lowdown is reported by name' );

	$render = App::FuguWeb::Render->new(
		config  => config(),
		mandoc  => '/bin/sh',
		lowdown => '/bin/sh',
		pod2man => '/bin/sh',
	);
	is( $render->probe, undef, 'three programs that exist pass' );
};

subtest 'the mandoc options carry the configured OS and manual URL' => sub {
	my $render = App::FuguWeb::Render->new( config => config( <<'RC' ) );
site      = Example
mandoc_os = Example OS
man_url   = https://man.example.org/
RC

	my @options = $render->html_options;
	my $joined  = join ' ', @options;

	# -I os= pins the footer. Without it the page would name the
	# operating system of the machine that built the site.
	like( $joined, qr/\Qos=Example OS\E/, 'the OS is pinned' );

	# The './' matters: a browser reads a relative URL whose first
	# segment holds a colon as a scheme.
	like( $joined, qr{\Qman=./%N.%S.html;https://man.example.org/%N.%S\E},
		'a local link stays local and a remote one leaves' );
	like( $joined, qr/fragment/, 'the output is a body fragment' );
};

SKIP: {
	skip 'mandoc not found', 2 unless have('mandoc');

	subtest 'lint accepts a clean page and rejects a malformed one' =>
	    sub {
		my $dir = tempdir( CLEANUP => 1 );

		open my $good, '>', "$dir/good.1"
		    or die "Cannot write the page: $!";
		print {$good} <<'MDOC';
.Dd $Mdocdate: July 27 2026 $
.Dt GOOD 1
.Os
.Sh NAME
.Nm good
.Nd a page that lints
.Sh DESCRIPTION
Words.
MDOC
		close $good;

		my $render =
		    App::FuguWeb::Render->new( config => config(),
			log => quiet() );
		ok( $render->lint("$dir/good.1"), 'a clean page passes' );
		ok( $render->lint, 'no page at all passes' );

		# A malformed page must fail the build, not render badly.
		open my $bad, '>', "$dir/bad.1"
		    or die "Cannot write the page: $!";
		print {$bad} ".Sh NAME\n.Nm bad\n";
		close $bad;

		ok( !$render->lint("$dir/bad.1"),
			'a page with no prologue fails' );
	    };

	subtest 'mdoc renders in the directory it is given' => sub {
		my $dir = tempdir( CLEANUP => 1 );
		make_path("$dir/stage");

		for my $name (qw(one.1 two.1)) {
			open my $fh, '>', "$dir/stage/$name"
			    or die "Cannot write the page: $!";
			my $stem = $name =~ s/\.1$//r;
			print {$fh} <<"MDOC";
.Dd \$Mdocdate: July 27 2026 \$
.Dt \U$stem\E 1
.Os
.Sh NAME
.Nm $stem
.Nd a staged page
.Sh SEE ALSO
.Xr two 1 ,
.Xr elsewhere 1
MDOC
			close $fh;
		}

		my $render = App::FuguWeb::Render->new(
			config => config(),
			log    => quiet(),
		);
		my $html = $render->mdoc( 'one.1', "$dir/stage" );
		ok( defined $html, 'the page renders' );

		# mandoc reads a .Xr target as a local link only when a
		# file named %N.%S sits in its working directory.
		like( $html, qr{href="\./two\.1\.html"},
			'a staged target becomes a local link' );
		like( $html, qr{href="https://man\.openbsd\.org/elsewhere\.1"},
			'a target that is not staged leaves for the host' );

		my $missing = $render->mdoc( 'one.1', "$dir/absent" );
		is( $missing, undef,
			'a staging directory that is absent fails' );
	};
}

done_testing();
