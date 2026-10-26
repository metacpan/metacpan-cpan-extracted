#!/usr/bin/env perl
# ex:ts=8 sw=4:
# App::FuguWeb::Render: the probe, the lint, the mandoc options, the
# Markdown render, and the arguments of pod2man.
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
sub config ( $rc = "site = Example\nurl = https://example.org/\n" )
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

subtest 'the mandoc options carry the manual URL' => sub {
	my $render = App::FuguWeb::Render->new( config => config( <<'RC' ) );
site    = Example
url     = https://example.org/
man_url = https://man.example.org/
RC

	# The './' matters: a browser reads a relative URL whose first
	# segment holds a colon as a scheme. The fit of
	# App::FuguWeb::Fragment removes the foot, so no option names the
	# operating system that the foot shows.
	is_deeply(
		[ $render->html_options ],
		[
			'-Thtml', '-O',
			'fragment,man=./%N.%S.html;https://man.example.org/%N.%S'
		],
		'a body fragment, where a local link stays local and a remote'
		    . ' one leaves'
	);
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

SKIP: {
	skip 'lowdown not found', 1 unless have('lowdown');

	subtest 'markdown keeps the HTML that the file holds' => sub {
		my $dir = tempdir( CLEANUP => 1 );
		open my $fh, '>', "$dir/page.md"
		    or die "Cannot write the page: $!";
		print {$fh} "One.\n\n<hr>\n\nTwo <kbd>x</kbd>.\n";
		close $fh;

		my $render = App::FuguWeb::Render->new(
			config => config(),
			log    => quiet(),
		);
		my $html = $render->markdown("$dir/page.md");
		ok( defined $html, 'the page renders' );
		like( $html, qr{<hr>}, 'an HTML block stays' );
		like( $html, qr{<kbd>x</kbd>}, 'an HTML span stays' );
	};
}

subtest 'each output decodes, and one that is not UTF-8 fails' => sub {
	# WEB-SITE-5. A renderer writes UTF-8, and the build reads its
	# output as characters. The message names the renderer and the
	# source.
	my $dir = tempdir( CLEANUP => 1 );
	my %script = (
		good => "printf 'voil\\303\\240\\n'",
		bad  => "printf 'caf\\351\\n'",
	);
	for my $name ( sort keys %script ) {
		open my $fh, '>', "$dir/$name" or die "Cannot write: $!";
		print {$fh} "#!/bin/sh\n$script{$name}\n";
		close $fh;
		chmod 0755, "$dir/$name" or die "Cannot chmod: $!";
	}

	my $render = App::FuguWeb::Render->new(
		config  => config(),
		log     => quiet(),
		lowdown => "$dir/good",
	);
	is( $render->markdown('page.md'), "voil\x{e0}\n",
		'an output of UTF-8 reads as characters' );

	my $said = '';
	open my $saved, '>&', \*STDERR or die "Cannot save stderr: $!";
	close STDERR;
	open STDERR, '>', \$said or die 'Cannot capture stderr';

	$render = App::FuguWeb::Render->new(
		config  => config(),
		log     => Fugu::Log->new,
		lowdown => "$dir/bad",
	);
	my $html = $render->markdown('page.md');

	close STDERR;
	open STDERR, '>&', $saved or die "Cannot restore stderr: $!";

	is( $html, undef, 'an output that is not UTF-8 fails' );
	like( $said,
		qr/the output of lowdown for page\.md is not valid UTF-8 at byte 3/,
		'and the message names the renderer and the source' );
};

subtest 'pod2man takes --utf8 and the sidecar alone' => sub {
	# WEB-SITE-5. Without --utf8, podlators 4.14 of perl 5.36 writes
	# X or a roff escape for each character outside ASCII. The name,
	# the section, the date, the center text and the release go to
	# the head and the foot alone, which the fit removes, per D-07.
	# A stub pod2man records its arguments, and a stub mandoc passes
	# its input through.
	my $dir = tempdir( CLEANUP => 1 );
	my %script = (
		pod2man => q{printf '%s\n' "$@" > "$0.args"; echo page},
		mandoc  => 'cat',
	);
	for my $name ( sort keys %script ) {
		open my $fh, '>', "$dir/$name" or die "Cannot write: $!";
		print {$fh} "#!/bin/sh\n$script{$name}\n";
		close $fh;
		chmod 0755, "$dir/$name" or die "Cannot chmod: $!";
	}

	my $render = App::FuguWeb::Render->new(
		config  => config(),
		log     => quiet(),
		mandoc  => "$dir/mandoc",
		pod2man => "$dir/pod2man",
	);
	is( $render->pod('Foo.pod'), "page\n", 'the sidecar renders' );

	open my $fh, '<', "$dir/pod2man.args" or die "Cannot read: $!";
	my @args = <$fh>;
	close $fh;
	chomp @args;
	is_deeply( \@args, [ '--utf8', 'Foo.pod' ],
		'and pod2man takes --utf8 and the sidecar, and no other argument' );
};

done_testing();
