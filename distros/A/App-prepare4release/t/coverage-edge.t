#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(is like);
use Cwd qw(getcwd);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

# --- fetch_latest_perl_release_version (MetaCPAN / HTTP branches) ------------
# Requires HTTP::Tiny; mock ->get to avoid network and cover fallbacks.

{
	require HTTP::Tiny;

	no warnings 'redefine';
	local $ENV{PREPARE4RELEASE_PERL_MAX};
	local *HTTP::Tiny::get = sub {
		return { success => 0, content => '' };
	};
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	is( App::prepare4release->fetch_latest_perl_release_version, '5.40',
		'fetch_latest: HTTP failure -> 5.40' );
	ok( ( grep { /MetaCPAN GET .*failed/ } @w ), 'warn on GET failure' );
}

{
	require HTTP::Tiny;
	no warnings 'redefine';
	local $ENV{PREPARE4RELEASE_PERL_MAX};
	local *HTTP::Tiny::get = sub {
		return { success => 1, content => 'not-json {{{' };
	};
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	is( App::prepare4release->fetch_latest_perl_release_version, '5.40',
		'fetch_latest: bad JSON -> 5.40' );
	ok( ( grep { /JSON decode failed/ } @w ), 'warn on JSON decode' );
}

{
	require HTTP::Tiny;
	no warnings 'redefine';
	local $ENV{PREPARE4RELEASE_PERL_MAX};
	local *HTTP::Tiny::get = sub {
		return { success => 1, content => '{"info":[]}' };
	};
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	is( App::prepare4release->fetch_latest_perl_release_version, '5.40',
		'fetch_latest: missing version field -> 5.40' );
	ok( ( grep { /no version/ } @w ), 'warn when version absent' );
}

{
	require HTTP::Tiny;
	no warnings 'redefine';
	local $ENV{PREPARE4RELEASE_PERL_MAX};
	local *HTTP::Tiny::get = sub {
		return { success => 1, content => '{"version":"not-a-perl-version-xyz"}' };
	};
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	is( App::prepare4release->fetch_latest_perl_release_version, '5.40',
		'fetch_latest: unparseable ceiling -> 5.40' );
	ok( ( grep { /Unexpected MetaCPAN/ } @w ), 'warn on bad ceiling' );
}

{
	require HTTP::Tiny;
	no warnings 'redefine';
	local $ENV{PREPARE4RELEASE_PERL_MAX};
	local *HTTP::Tiny::get = sub {
		return { success => 1, content => '{"version":"5.008008"}' };
	};
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	is( App::prepare4release->fetch_latest_perl_release_version, '5.40',
		'fetch_latest: ceiling minor < 5.10 -> 5.40' );
	ok( ( grep { /below 5\.10/ } @w ), 'warn on ancient ceiling' );
}

{
	require HTTP::Tiny;
	no warnings 'redefine';
	local $ENV{PREPARE4RELEASE_PERL_MAX};
	local *HTTP::Tiny::get = sub {
		return { success => 1, content => '{"version":"5.042000"}' };
	};
	is( App::prepare4release->fetch_latest_perl_release_version, '5.42',
		'fetch_latest: successful MetaCPAN parse' );
}

# --- apply_ci_files: empty Perl matrix --------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	open my $m, '>', File::Spec->catfile( $tmp, 'Makefile.PL' ) or die $!;
	print {$m} "use ExtUtils::MakeMaker;\n";
	close $m;

	my $vf = File::Spec->catfile( $tmp, 'Old.pm' );
	open my $p, '>', $vf or die $!;
	print {$p} "package Old;\nuse v5.20;\n1;\n";
	close $p;

	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	local $ENV{PREPARE4RELEASE_PERL_MAX} = '5.10';

	App::prepare4release->apply_ci_files(
		$tmp,
		{ github => 1 },
		{},
		'',
		{ version_from_path => $vf },
		1
	);

	ok( ( grep { /empty Perl matrix/ } @w ), 'empty matrix skips CI files' );
	ok( !-e File::Spec->catfile( $tmp, '.github', 'workflows', 'ci.yml' ),
		'no ci.yml when matrix empty' );
}

# --- split_pm_code_and_pod without __END__ ----------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	my $pm = File::Spec->catfile( $tmp, 'noend.pm' );
	open my $fh, '>', $pm or die $!;
	print {$fh} "package X;\n1;\n";
	close $fh;

	my ( $c, $pod ) = App::prepare4release->split_pm_code_and_pod($pm);
	like( $c, qr/package X/, 'code only' );
	is( $pod, '', 'no pod without __END__' );
}

# --- regenerate_readme_md: no version file ----------------------------------

{
	my $d = tempdir( CLEANUP => 1 );
	my $rc = App::prepare4release->regenerate_readme_md(
		$d,
		{},
		{ version_from_path => undef },
		0
	);
	ok( !$rc, 'regenerate_readme_md returns 0 without vf' );
}

# --- regenerate_readme_md: tool failure -------------------------------------
# Use symlink to /bin/false so -x is reliable under prove + Devel::Cover.

{
	my $here = getcwd;
	my $bin  = tempdir( DIR => $here, CLEANUP => 1 );
	my $exe  = File::Spec->catfile( $bin, 'pod2markdown' );
	symlink( '/bin/false', $exe ) or die "symlink: $!";

	my $d = tempdir( CLEANUP => 1 );
	my $vf = File::Spec->catfile( $d, 'P.pm' );
	open my $p, '>', $vf or die $!;
	print {$p} "=pod\n=cut\n";
	close $p;
	open my $r, '>', File::Spec->catfile( $d, 'README.md' ) or die $!;
	print {$r} "x\n";
	close $r;

	local $ENV{PATH} = join ':', $bin, '/bin', '/usr/bin';

	my $rc = App::prepare4release->regenerate_readme_md(
		$d,
		{},
		{ version_from_path => $vf },
		0
	);
	ok( !$rc, 'regenerate_readme_md 0 when pod2markdown exits non-zero' );
}

# --- license_badge_info keys ------------------------------------------------

{
	my ( $a, $b ) = App::prepare4release->license_badge_info('apache_2');
	ok( $a && $b, 'apache_2 badge tuple' );
	my ( $c, $d ) = App::prepare4release->license_badge_info('gpl_3');
	ok( $c && $d, 'gpl_3 badge tuple' );
}

# --- infer_license_key_from_text (more lines) -------------------------------

{
	is( App::prepare4release->infer_license_key_from_text(
			'GNU GENERAL PUBLIC LICENSE Version 3'
		),
		'gpl_3',
		'infer gpl_3'
	);
	is( App::prepare4release->infer_license_key_from_text(
			'GNU LESSER GENERAL PUBLIC LICENSE Version 3'
		),
		'lgpl_3',
		'infer lgpl_3'
	);
}

# --- perl_min_badge_label malformed -----------------------------------------

{
	is( App::prepare4release->perl_min_badge_label('not-a-version'),
		'5.10%2B',
		'perl_min_badge_label fallback for garbage' );
}

# --- ensure_meta_merge skip when URLs already match -------------------------

{
	my $same_git = 'git://example/repo.git';
	my $same_web = 'https://example/web';
	my $same_bug = 'https://example/bugs';
	my $content  = <<"MK";
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Z',
  META_MERGE => {
    resources => {
      repository => { url => '$same_git', web => '$same_web' },
      bugtracker => { web => '$same_bug' },
    },
  },
);
MK
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	my $out = App::prepare4release->ensure_meta_merge(
		$content, $same_git, $same_web, $same_bug, 1 );
	is( $out, $content, 'ensure_meta_merge skip when URLs match' );
	ok( ( grep { /already match/ } @w ), 'verbose skip message' );
}

done_testing;
