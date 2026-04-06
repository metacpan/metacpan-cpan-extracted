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

sub _write_minimal_dist {
	my ($root) = @_;
	my $j = File::Spec->catfile( $root, 'prepare4release.json' );
	open my $fj, '>:encoding(UTF-8)', $j or die $!;
	print {$fj} qq({"git":{"repo":"testuser/p4r-int"},"dependencies":{"skip":true}}\n);
	close $fj;

	my $mf = File::Spec->catfile( $root, 'Makefile.PL' );
	open my $fm, '>:encoding(UTF-8)', $mf or die $!;
	print {$fm} <<'MK';
use 5.010;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Foo::Bar',
    VERSION_FROM     => 'lib/Foo/Bar.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010001',
);
MK
	close $fm;

	make_path( File::Spec->catfile( $root, 'lib', 'Foo' ) );
	my $pm = File::Spec->catfile( $root, 'lib', 'Foo', 'Bar.pm' );
	open my $fp, '>:encoding(UTF-8)', $pm or die $!;
	print {$fp} <<'PM';
package Foo::Bar;
use strict;
use warnings;
our $VERSION = '0.01';
use v5.10;
1;
__END__

=head1 NAME

Foo::Bar

=begin html

<!-- PREPARE4RELEASE_BADGES -->
<!-- /PREPARE4RELEASE_BADGES -->

=end html

=cut
PM
	close $fp;

	make_path( File::Spec->catfile( $root, 't' ) );
	my $tt = File::Spec->catfile( $root, 't', 'smoke.t' );
	open my $ft, '>:encoding(UTF-8)', $tt or die $!;
	print {$ft} <<'TT';
#!perl
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
ok(1);
done_testing;
TT
	close $ft;

	my $readme = File::Spec->catfile( $root, 'README.md' );
	open my $fr, '>:encoding(UTF-8)', $readme or die $!;
	print {$fr} "# Foo::Bar\n\nTiny module.\n";
	close $fr;
}

# --- integration: full run() in temp project --------------------------------
# run() -> parse_argv uses FindBin for pod2usage; after chdir away from the
# project tree the relative path to this .t file breaks FindBin. Use fork+exec
# with perl -e so the child has a synthetic $0 and FindBin resolves under /tmp.

{
	my $tmp  = tempdir( CLEANUP => 1 );
	my $here = getcwd;
	_write_minimal_dist($tmp);

	my $blib = File::Spec->catfile( $here, 'lib' );
	local $ENV{PREPARE4RELEASE_PERL_MAX} = '5.20';

	require Config;
	my $can_fork = $Config::Config{d_fork};
	my $exit_code;
	if ($can_fork) {
		my $pid = fork;
		die "fork: $!" unless defined $pid;
		if ( !$pid ) {
			chdir $tmp or exit 126;
			exec $^X, '-I', $blib, '-MApp::prepare4release', '-e',
				'exit App::prepare4release->run(@ARGV)', '--',
				'--verbose', '--github', '--cpan'
				or exit 127;
		}
		waitpid( $pid, 0 );
		$exit_code = $? >> 8;
	}
	else {
		$exit_code = system(
			$^X, '-I', $blib, '-MApp::prepare4release', '-e',
			'chdir $ARGV[0] or exit 126; exit App::prepare4release->run(@ARGV[1..$#ARGV])',
			'--', $tmp, '--verbose', '--github', '--cpan'
		);
		$exit_code = $? >> 8;
	}

	is( $exit_code, 0, 'run() returns 0 (exec helper)' );

	my $ci = File::Spec->catfile( $tmp, '.github', 'workflows', 'ci.yml' );
	ok( -e $ci, 'GitHub workflow created' );

	my $mf = File::Spec->catfile( $tmp, 'Makefile.PL' );
	open my $fh, '<:encoding(UTF-8)', $mf or die $!;
	local $/;
	my $mpl = <$fh>;
	close $fh;
	like( $mpl, qr/pod2github/, 'Makefile.PL gained pod2github postamble' );
	like( $mpl, qr/maint\/inject-readme-badges\.pl/,
		'Makefile.PL postamble runs maint/inject-readme-badges.pl' );
	like( $mpl, qr/META_MERGE/, 'Makefile.PL has META_MERGE' );

	my $read = File::Spec->catfile( $tmp, 'README.md' );
	open my $rh, '<:encoding(UTF-8)', $read or die $!;
	local $/;
	my $body = <$rh> // '';
	close $rh;
	like( $body, qr/MetaCPAN package/, 'README badges (--cpan)' );

	my $vf = File::Spec->catfile( $tmp, 'lib', 'Foo', 'Bar.pm' );
	open my $vh, '<:encoding(UTF-8)', $vf or die $!;
	local $/;
	my $pmsrc = <$vh> // '';
	close $vh;
	unlike( $pmsrc, qr/PREPARE4RELEASE_BADGES/,
		'legacy POD badge block stripped from .pm' );

	ok( -e File::Spec->catfile( $tmp, 'xt', 'author', 'pod.t' ),
		'ensure_xt_author_tests created xt/author/pod.t' );
}

# --- warn_legacy_test_frameworks ---------------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	make_path( File::Spec->catfile( $tmp, 't' ) );
	my $leg = File::Spec->catfile( $tmp, 't', 'old.t' );
	open my $fh, '>:encoding(UTF-8)', $leg or die $!;
	print {$fh} "use Test::More tests => 1;\nok 1;\n";
	close $fh;

	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	App::prepare4release->warn_legacy_test_frameworks($tmp);
	ok( ( grep { /legacy assertion/i } @w ), 'warns on Test::More in t/*.t' );
}

# --- parse_pm_identity / resolve_identity ------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	make_path( File::Spec->catfile( $tmp, 'lib' ) );
	my $pm = File::Spec->catfile( $tmp, 'lib', 'Z.pm' );
	open my $fh, '>:encoding(UTF-8)', $pm or die $!;
	print {$fh} <<'PM';
package Z::Mod;
our $VERSION = '1.02';
1;
PM
	close $fh;

	my ( $pkg, $ver ) = App::prepare4release->parse_pm_identity($pm);
	is( $pkg, 'Z::Mod', 'parse_pm_identity package' );
	is( $ver, '1.02', 'parse_pm_identity version' );

	my $id = App::prepare4release->resolve_identity(
		$tmp,
		{},
		{ version_from => 'lib/Z.pm', name => 'Z::Mod' }
	);
	is( $id->{module_name}, 'Z::Mod', 'resolve_identity from VERSION_FROM' );
	ok( $id->{version_from_path}, 'version_from_path set' );
}

# --- min_perl_version_from_pm_content (decimal use 5.x) ----------------------

{
	my $got = App::prepare4release->min_perl_version_from_pm_content(<<'PM');
package Q;
use 5.014;
PM
	ok( defined $got, 'min perl from use 5.014' );
	like( $got, qr/^v5\.14/, 'normalizes to v5.14' );
}

# --- _minor_from_version_token via perl_matrix_tags --------------------------

{
	my @m = App::prepare4release->perl_matrix_tags( '5.008007', '5.20' );
	ok( scalar @m >= 1, 'matrix from 5.008007 floor token' );
	ok( ( grep { $_ eq '5.8' } @m ), '5.008007 floor yields 5.8 minor in matrix' );
}

# --- write_makefile_close_index / ensure_postamble ---------------------------

{
	my $pair = App::prepare4release->write_makefile_close_index(<<'MK');
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'X',
);
MK
	ok( $pair && @$pair == 2, 'write_makefile_close_index finds closing paren' );

	my $base = <<'MK';
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'X',
);
MK
	my $patched = App::prepare4release->ensure_postamble( $base,
		{ github => 0, gitlab => 0, cpan => 0 }, 0 );
	like( $patched, qr/pod2markdown/, 'ensure_postamble adds pod2markdown' );
}

# --- find_lib_pm_files ------------------------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	make_path( File::Spec->catfile( $tmp, 'lib', 'A' ) );
	my $pm = File::Spec->catfile( $tmp, 'lib', 'A', 'B.pm' );
	open my $fh, '>', $pm or die $!;
	print {$fh} "1;\n";
	close $fh;
	my @f = App::prepare4release->find_lib_pm_files($tmp);
	ok( ( grep { /B\.pm\z/ } @f ), 'find_lib_pm_files finds lib/**/*.pm' );
}

# --- load_config_file invalid JSON -----------------------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	my $p = File::Spec->catfile( $tmp, 'bad.json' );
	open my $fh, '>', $p or die $!;
	print {$fh} "{ not json";
	close $fh;

	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };

	my $cfg = App::prepare4release->load_config_file($p);
	is( ref $cfg, 'HASH', 'load_config_file returns hashref on invalid JSON' );
	is( scalar keys %$cfg, 0, 'invalid JSON yields empty object' );
	ok( scalar @warn, 'invalid JSON warns' );
	like( $warn[0], qr/invalid JSON/, 'warning mentions invalid JSON' );
}

# --- resolve_config_path explicit --------------------------------------------

{
	my $p = '/tmp/will-not-read-resolve.t';
	is( App::prepare4release->resolve_config_path($p),
		$p, 'resolve_config_path returns explicit path' );
}

# --- apply_ci_files (matrix + alien verbose path) ---------------------------

{
	my $tmp = tempdir( CLEANUP => 1 );
	open my $m, '>', File::Spec->catfile( $tmp, 'Makefile.PL' ) or die $!;
	print {$m} "use Alien::Zoo;\n";
	close $m;

	my $vf = File::Spec->catfile( $tmp, 'M.pm' );
	open my $v, '>', $vf or die $!;
	print {$v} "package M;\nuse v5.12;\n1;\n";
	close $v;

	my @w;
	local $SIG{__WARN__} = sub { push @w, join '', @_ };
	local $ENV{PREPARE4RELEASE_PERL_MAX} = '5.18';

	App::prepare4release->apply_ci_files(
		$tmp,
		{ github => 1 },
		{ ci => { apt_packages => ['libfoo-dev'] } },
		'MIN_PERL_VERSION => \'5.012003\',',
		{ version_from_path => $vf },
		1
	);

	ok( ( grep { /Zoo/ } @w ),
		'verbose apply_ci_files mentions Alien scan hit' );
	my $ci = File::Spec->catfile( $tmp, '.github', 'workflows', 'ci.yml' );
	ok( -e $ci, 'apply_ci_files wrote ci.yml' );
	open my $ch, '<', $ci or die $!;
	local $/;
	my $cy = <$ch>;
	close $ch;
	like( $cy, qr/libfoo-dev/, 'apt_packages in generated CI' );
}

done_testing;
