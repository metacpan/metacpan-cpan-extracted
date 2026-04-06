#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(is like unlike);
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

sub _app {
	my (%p) = @_;
	App::prepare4release->new(
		config   => $p{config} // {},
		opts     => $p{opts} // {},
		identity => {
			module_name => $p{module} // 'Foo::Bar',
			dist_name   => $p{dist}   // 'Foo-Bar',
			%{ $p{identity} // {} },
		},
	);
}

# --- _git_path_segment_or_short_repo via repository_path_segment --------------

{
	my $a = _app(
		config => { git => { repo => 'https://gitlab.example.com/acme/proj' } },
	);
	is( $a->repository_path_segment, 'acme/proj', 'https git.repo URL path' );
}

{
	my $a = _app(
		config => { git => { repo => 'git@git.example.org:grp/name.git' } },
	);
	is( $a->repository_path_segment, 'grp/name', 'git@ scp-style repo' );
}

# --- module_repo ------------------------------------------------------------

{
	my $a = _app(
		config => {
			git => {
				author => 'alice',
				repo   => 'shortname',
			}
		},
		module => 'Foo::Bar',
	);
	is( $a->module_repo, 'shortname', 'module_repo uses short repo + author path' );
}

{
	my $a = _app(
		config => { git => { repo => 'namespace/full' } },
		module => 'Foo::Bar',
	);
	is( $a->module_repo, 'namespace/full', 'module_repo uses namespace/repo' );
}

# --- bugtracker_url default -------------------------------------------------

{
	my $a = _app(
		config => { git => { repo => 'u/r' } },
		opts   => { github => 1 },
		module => 'M',
	);
	like( $a->bugtracker_url, qr{github\.com/u/r/issues\z}, 'default bugtracker issues URL' );
}

# --- makefile_pl_path / read_makefile_pl_snippets ---------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	open my $fh, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'Makefile.PL' )
		or die $!;
	print {$fh} <<'MK';
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Z::Mod',
  VERSION_FROM => 'lib/Z.pm',
  LICENSE => 'perl',
);
MK
	close $fh;

	my $here = getcwd;
	chdir $tmp or die $!;
	my $mp = App::prepare4release->makefile_pl_path;
	ok( $mp && -e $mp, 'makefile_pl_path finds Makefile.PL' );
	my ( $content, $sn ) = App::prepare4release->read_makefile_pl_snippets($mp);
	chdir $here or die $!;
	like( $content, qr/WriteMakefile/, 'read_makefile_pl_snippets content' );
	is( $sn->{name}, 'Z::Mod', 'snippet NAME' );
	is( $sn->{version_from}, 'lib/Z.pm', 'snippet VERSION_FROM' );
}

# --- ensure_postamble branches ----------------------------------------------

{
	my $gh = App::prepare4release->ensure_postamble( "WriteMakefile( NAME => 'X', );\n",
		{ github => 1, gitlab => 0, cpan => 0 }, 0 );
	like( $gh, qr/pod2github/, 'ensure_postamble adds pod2github' );
	like( $gh, qr/maint\/inject-readme-badges\.pl/, 'ensure_postamble adds inject script' );

	my $skip1 = App::prepare4release->ensure_postamble(
		"use ExtUtils::MakeMaker;\npod2github\n",
		{ github => 1, gitlab => 0, cpan => 0 }, 0
	);
	is( $skip1, "use ExtUtils::MakeMaker;\npod2github\n",
		'skip when pod2github already present' );

	my $skip2 = App::prepare4release->ensure_postamble(
		"pod2markdown\n",
		{ github => 1, gitlab => 0, cpan => 0 }, 0
	);
	is( $skip2, "pod2markdown\n",
		'want pod2github but pod2markdown present: skip' );

	my $skip3 = App::prepare4release->ensure_postamble(
		"pod2markdown\n",
		{ github => 0, gitlab => 0, cpan => 0 }, 0
	);
	is( $skip3, "pod2markdown\n", 'skip when pod2markdown already (want md)' );

	my $skip4 = App::prepare4release->ensure_postamble(
		"pod2github\n",
		{ github => 0, gitlab => 0, cpan => 0 }, 0
	);
	is( $skip4, "pod2github\n", 'want md but pod2github: skip' );

	my $has_post = App::prepare4release->ensure_postamble(
		"sub MY::postamble { return ''; }\n",
		{ github => 1, gitlab => 0, cpan => 0 }, 1
	);
	like( $has_post, qr/MY::postamble/, 'existing MY::postamble without pod2: not merged' );
}

# --- write_makefile_close_index ---------------------------------------------

{
	my $u = App::prepare4release->write_makefile_close_index('use strict;');
	ok( !defined $u, 'write_makefile_close_index undef without WriteMakefile' );
}

# --- ensure_meta_merge insert + patch --------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	my $mf = File::Spec->catfile( $tmp, 'Makefile.PL' );
	my $orig = <<'MK';
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Y::Mod',
);
MK
	open my $o, '>:encoding(UTF-8)', $mf or die $!;
	print {$o} $orig;
	close $o;

	open my $i, '<:encoding(UTF-8)', $mf or die $!;
	local $/;
	my $c = <$i>;
	close $i;

	my $patched = App::prepare4release->ensure_meta_merge(
		$c,
		'git://x.git',
		'https://web/x',
		'https://bugs/x',
		0
	);
	like( $patched, qr/META_MERGE/, 'ensure_meta_merge inserts META_MERGE' );
	like( $patched, qr/git:\/\/x\.git/, 'inserted repo git URL' );
}

{
	my $has = <<'MK';
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Z',
  META_MERGE => {
    resources => {
      repository => { url => 'OLDU', web => 'OLDW' },
      bugtracker => { web => 'OLDB' },
    },
  },
);
MK
	my $out = App::prepare4release->_patch_meta_merge_block(
		$has, 'NEWU', 'NEWW', 'NEWB', 0 );
	like( $out, qr/NEWU/, 'patch meta url' );
	like( $out, qr/NEWW/, 'patch meta web' );
	like( $out, qr/NEWB/, 'patch bugtracker web' );
}

{
	my $no_bug = <<'MK';
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Z',
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => { url => 'U', web => 'W' },
    },
  },
);
MK
	my $out = App::prepare4release->_patch_meta_merge_block(
		$no_bug, 'U2', 'W2', 'B2', 0 );
	like( $out, qr/bugtracker/, 'inject bugtracker into resources' );
}

# --- croak paths ------------------------------------------------------------

{
	eval { App::prepare4release->package_to_repo_default('') };
	like( $@, qr/module_name required/, 'package_to_repo_default croaks' );
}

{
	eval {
		my $a = _app(
			config => { git => { repo => 'onlyshort' } },
			module => 'Foo::Bar',
		);
		$a->repository_path_segment;
	};
	like( $@, qr/git\.author/, 'repository_path_segment croaks without author' );
}

{
	eval {
		App::prepare4release->new(
			config   => {},
			opts     => {},
			identity => {},
		)->module_repo;
	};
	like( $@, qr/module_name is required/, 'module_repo croaks' );
}

# --- _insert_readme_badges_after_regen (BOM, empty) --------------------------

{
	my $bom = "\x{FEFF}Plain first line\n";
	my $out =
		App::prepare4release->_insert_readme_badges_after_regen( $bom, "BAD\n\n" );
	unlike( $out, qr/\A\x{FEFF}/, 'BOM stripped before insert' );
	like( $out, qr/BAD/, 'badge block inserted' );

	my $empty =
		App::prepare4release->_insert_readme_badges_after_regen( "\n\n", "X\n" );
	like( $empty, qr/\AX\n/, 'whitespace-only readme: block prepended' );
}

# --- _strip_readme_badge_markdown_block (HTML comment) ----------------------

{
	my $html = <<'MD';
Before
<!-- PREPARE4RELEASE_BADGES -->
old
<!-- /PREPARE4RELEASE_BADGES -->
After
MD
	my $s = App::prepare4release->_strip_readme_badge_markdown_block($html);
	unlike( $s, qr/PREPARE4RELEASE_BADGES/, 'strip HTML badge comment wrapper' );
	like( $s, qr/After/, 'keeps text after comment block' );
}

# --- _collect_t_files -------------------------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	make_path( File::Spec->catfile( $tmp, 't', 'sub' ) );
	make_path( File::Spec->catfile( $tmp, 'xt' ) );
	for (
		[ 't',  'a.t' ],
		[ 'xt', 'b.t' ]
		)
	{
		my $p = File::Spec->catfile( $tmp, @{$_} );
		open my $fh, '>', $p or die $!;
		print {$fh} "1;\n";
		close $fh;
	}
	my @f = App::prepare4release->_collect_t_files($tmp);
	ok( ( grep { $_ eq 't/a.t' } @f ) && ( grep { $_ eq 'xt/b.t' } @f ),
		'_collect_t_files finds t and xt' );
}

# --- strip_pod_badges_from_version_from (no-op) -----------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	my $pm = File::Spec->catfile( $tmp, 'N.pm' );
	open my $fh, '>', $pm or die $!;
	print {$fh} <<'PM';
package N;
1;
__END__
=head1 X
=cut
PM
	close $fh;
	my $before = do { open my $i, '<', $pm; local $/; <$i> };
	App::prepare4release->strip_pod_badges_from_version_from( $pm, 0 );
	my $after = do { open my $i, '<', $pm; local $/; <$i> };
	is( $after, $before, 'strip_pod_badges no-op when no PREPARE4RELEASE in POD' );
}

# --- apply_readme_badges skips ----------------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	App::prepare4release->apply_readme_badges(
		$tmp,
		{ github => 1 },
		_app(),
		'',
		{ license => 'perl' },
		{ version_from_path => '/nope/not.pm' },
		1
	);
	ok( ( grep { /README\.md missing/i } @w ), 'apply_readme badges: no README' );

	@w = ();
	open my $r, '>', File::Spec->catfile( $tmp, 'README.md' ) or die $!;
	print {$r} "# x\n";
	close $r;
	App::prepare4release->apply_readme_badges(
		$tmp,
		{ github => 1 },
		_app(),
		'',
		{ license => 'perl' },
		{ version_from_path => undef },
		1
	);
	ok( ( grep { /VERSION_FROM|no VERSION/i } @w ),
		'apply_readme badges: no version_from path' );
}

# --- regenerate_readme_md via Makefile --------------------------------------

{
	my $d = tempdir( CLEANUP => 1 );
	my $vf = File::Spec->catfile( $d, 'lib.pm' );
	open my $p, '>', $vf or die $!;
	print {$p} "1;\n";
	close $p;
	open my $mk, '>', File::Spec->catfile( $d, 'Makefile' ) or die $!;
	print {$mk} "README.md: lib.pm\n";
	print {$mk} "\t\@echo make-generated > README.md\n";
	close $mk;

	my $id = { version_from_path => $vf };
	my $rc = App::prepare4release->regenerate_readme_md( $d, {}, $id, 0 );
	ok( $rc, 'regenerate_readme_md via make README.md' );
	open my $in, '<', File::Spec->catfile( $d, 'README.md' ) or die $!;
	local $/;
	like( <$in>, qr/make-generated/, 'README from make' );
}

# --- ensure_* verbose skip ---------------------------------------------------

{
	my $d = tempdir( CLEANUP => 1 );
	my $y = 'y: 1';
	App::prepare4release->ensure_github_workflow( $d, $y, 0 );
	App::prepare4release->ensure_gitlab_ci( $d, $y, 0 );
	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	App::prepare4release->ensure_github_workflow( $d, $y, 1 );
	App::prepare4release->ensure_gitlab_ci( $d, $y, 1 );
	ok(
		( grep { /already exists, skipping/ } @w ) >= 2,
		'ensure_* verbose when file exists'
	);
}

# --- apply_ci_files GitLab only ---------------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	open my $m, '>', File::Spec->catfile( $tmp, 'Makefile.PL' ) or die $!;
	print {$m} "use v5.10;\n";
	close $m;
	my $vf = File::Spec->catfile( $tmp, 'P.pm' );
	open my $p, '>', $vf or die $!;
	print {$p} "package P;\nuse v5.10;\n1;\n";
	close $p;

	local $ENV{PREPARE4RELEASE_PERL_MAX} = '5.16';
	App::prepare4release->apply_ci_files(
		$tmp,
		{ gitlab => 1 },
		{},
		'',
		{ version_from_path => $vf },
		0
	);
	ok( -e File::Spec->catfile( $tmp, '.gitlab-ci.yml' ),
		'apply_ci_files writes GitLab only' );
}

# --- render_* empty matrix --------------------------------------------------

{
	my $g = App::prepare4release->render_github_ci_yml( [], [] );
	like( $g, qr/perl-version:/, 'render_github_ci_yml empty matrix' );
	my $l = App::prepare4release->render_gitlab_ci_yml( [], [] );
	like( $l, qr/PERL_VERSION:/, 'render_gitlab_ci_yml empty matrix' );
}

# --- perl_matrix_tags empty -------------------------------------------------

{
	my @z = App::prepare4release->perl_matrix_tags( 'v5.30.0', '5.20' );
	is( scalar @z, 0, 'perl_matrix_tags empty when floor above ceiling' );
}

# --- _metacpan_perl_version_to_ceiling_tag ----------------------------------

{
	ok( !defined App::prepare4release->_metacpan_perl_version_to_ceiling_tag(''),
		'ceiling tag undef for empty' );
}

# --- build_pod_badge_markdown GitLab CI row ---------------------------------

{
	my $md = App::prepare4release->build_pod_badge_markdown(
		'/tmp',
		_app( config => { git => { repo => 'g/p', server => 'gitlab.x.org' } } ),
		{ gitlab => 1 },
		0,
		{ license => 'perl' },
		{ module_name => 'A::B', dist_name => 'A-B' },
		'v5.10.0'
	);
	like( $md, qr/pipeline\.svg/, 'GitLab CI badge in markdown' );
	unlike( $md, qr/github\.com.*ci\.yml/, 'no GitHub CI row' );
}

# --- license_badge_label_and_href without VCS blob ---------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	my $mf = { license => 'mit' };
	my ( $lbl, $href ) = App::prepare4release->license_badge_label_and_href(
		$tmp,
		{},
		_app( config => {} ),
		$mf
	);
	like( $href, qr/opensource\.org/, 'license href canonical without --github/--gitlab' );
}

# --- infer_license_key_from_license_file ------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	open my $fh, '>:encoding(UTF-8)', File::Spec->catfile( $tmp, 'LICENSE' );
	print {$fh} "Apache License Version 2.0\n";
	close $fh;
	is( App::prepare4release->infer_license_key_from_license_file(
			File::Spec->catfile( $tmp, 'LICENSE' )
		),
		'apache_2',
		'infer apache_2 from LICENSE file'
	);
}

# --- scan_files_for_alien_hints cpanfile ------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	open my $c, '>', File::Spec->catfile( $tmp, 'cpanfile' ) or die $!;
	print {$c} "requires 'Alien::libpq', '> 0';\n";
	close $c;
	my @a = App::prepare4release->scan_files_for_alien_hints($tmp);
	ok( ( grep { $_ eq 'libpq' } @a ), 'Alien from cpanfile' );
}

# --- min_perl_version_from_pm_content v5.8 style ----------------------------

{
	my $v =
		App::prepare4release->min_perl_version_from_pm_content('use v5.8.8;');
	ok( defined $v, 'min perl from use v5.8.8' );
}

# --- file_uses_legacy_assertion_framework Test::Most -------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	my $f = File::Spec->catfile( $tmp, 'm.t' );
	open my $fh, '>', $f or die $!;
	print {$fh} "use Test::Most;\n";
	close $fh;
	ok( App::prepare4release->file_uses_legacy_assertion_framework($f),
		'detect Test::Most' );
}

# --- git_default_branch ------------------------------------------------------

{
	is( App::prepare4release->git_default_branch( { git => { default_branch => 'devel' } } ),
		'devel', 'git_default_branch from config' );
}

# --- new() ------------------------------------------------------------------

{
	my $o = App::prepare4release->new(
		config => { a => 1 },
		opts   => { github => 1 },
		identity => { module_name => 'M' },
	);
	is( $o->{config}{a}, 1, 'new() stores config' );
	is( $o->{opts}{github}, 1, 'new() stores opts' );
}

# --- resolve_identity from lib/**/*.pm only ----------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	make_path( File::Spec->catfile( $tmp, 'lib' ) );
	my $pm = File::Spec->catfile( $tmp, 'lib', 'Only.pm' );
	open my $fh, '>', $pm or die $!;
	print {$fh} <<'PM';
package Only::Lib;
our $VERSION = 3;
1;
PM
	close $fh;

	my $id = App::prepare4release->resolve_identity(
		$tmp,
		{},
		{}
	);
	is( $id->{module_name}, 'Only::Lib', 'resolve_identity from first lib pm' );
	ok( $id->{version_from_path}, 'version_from_path from scan' );
}

# --- ensure_xt_author_tests writes eol.t list -------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	make_path( File::Spec->catfile( $tmp, 'lib' ) );
	open my $pm, '>', File::Spec->catfile( $tmp, 'lib', 'E.pm' ) or die $!;
	print {$pm} "package E; our \$VERSION=1; 1;\n";
	close $pm;

	App::prepare4release->ensure_xt_author_tests( $tmp, 0 );
	my $eol = File::Spec->catfile( $tmp, 'xt', 'author', 'eol.t' );
	ok( -e $eol, 'eol.t created' );
	open my $in, '<', $eol or die $!;
	local $/;
	my $b = <$in>;
	like( $b, qr/lib\/E\.pm/, 'eol.t lists scanned files' );
}

# --- integration: run --gitlab --------------------------------------------

sub _write_dist_gitlab {
	my ($root) = @_;
	open my $fj, '>:encoding(UTF-8)', File::Spec->catfile( $root, 'prepare4release.json' );
	print {$fj} qq({"git":{"repo":"group/gitlab-proj"},"dependencies":{"skip":true}}\n);
	close $fj;
	open my $fm, '>:encoding(UTF-8)', File::Spec->catfile( $root, 'Makefile.PL' );
	print {$fm} <<'MK';
use 5.010;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'G::Lab',
    VERSION_FROM => 'lib/G/Lab.pm',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.010001',
);
MK
	close $fm;
	make_path( File::Spec->catfile( $root, 'lib', 'G' ) );
	open my $fp, '>:encoding(UTF-8)', File::Spec->catfile( $root, 'lib', 'G', 'Lab.pm' );
	print {$fp} <<'PM';
package G::Lab;
our $VERSION = '0.01';
use v5.10;
1;
__END__
=head1 N
=cut
PM
	close $fp;
	make_path( File::Spec->catfile( $root, 't' ) );
	open my $ft, '>', File::Spec->catfile( $root, 't', 'x.t' );
	print {$ft} "use Test2::V1; ok 1; done_testing;\n";
	close $ft;
	open my $fr, '>', File::Spec->catfile( $root, 'README.md' );
	print {$fr} "# G::Lab\n";
	close $fr;
}

{
	my $tmp  = tempdir( CLEANUP => 1 );
	my $here = getcwd;
	_write_dist_gitlab($tmp);
	my $blib = File::Spec->catfile( $here, 'lib' );
	local $ENV{PREPARE4RELEASE_PERL_MAX} = '5.18';

	require Config;
	my $exit_code;
	if ( $Config::Config{d_fork} ) {
		my $pid = fork;
		die "fork: $!" unless defined $pid;
		if ( !$pid ) {
			chdir $tmp or exit 126;
			exec $^X, '-I', $blib, '-MApp::prepare4release', '-e',
				'exit App::prepare4release->run(@ARGV)', '--',
				'--verbose', '--gitlab', '--cpan'
				or exit 127;
		}
		waitpid( $pid, 0 );
		$exit_code = $? >> 8;
	}
	else {
		$exit_code = system(
			$^X, '-I', $blib, '-MApp::prepare4release', '-e',
			'chdir $ARGV[0] or exit 126; exit App::prepare4release->run(@ARGV[1..$#ARGV])',
			'--', $tmp, '--verbose', '--gitlab', '--cpan'
		);
		$exit_code = $? >> 8;
	}

	is( $exit_code, 0, 'run --gitlab --cpan' );
	ok( -e File::Spec->catfile( $tmp, '.gitlab-ci.yml' ), '.gitlab-ci.yml created' );
	my $read = File::Spec->catfile( $tmp, 'README.md' );
	open my $rh, '<', $read or die $!;
	local $/;
	like( <$rh>, qr/pipeline\.svg|gitlab/i, 'README GitLab CI badge' );
}

done_testing;
