#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The dry-run trace of the deps verb equals the trace of the synced
# scripts/deps, line for line, over the manifests of every consumer
# (CLI-CONFORMANCE-2).
#
# The fixtures under t/fugubench/deps/ are copies of the manifests
# and the digest files of the thirteen consumers. A copy holds its
# own state, so a later change of a consumer does not reach it.
#
# Each pair runs the script and the verb over one fixture, one
# environment, one system name, and one machine name. Both children
# run under this perl, with one PATH that holds a stub downloader and
# no cpanm. The stub answers the signed-manifest probe of the script,
# so no pair asks the network.
#
# Two parts of a download line cannot match byte for byte. The script
# names the absolute path of its ftp helper, and the verb downloads
# in-process. Each side also names a temporary directory of its own.
# The comparison replaces the helper path with `fugubench fetch`, and
# each temporary directory with one token. It compares the '+ ' lines
# and changes nothing else.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Cwd        qw(abs_path);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use FindBin    qw($RealBin);
use POSIX      qw(uname);
use lib "$RealBin/../../lib";

use Fugu::File;
use Fugu::Process;

my $root    = abs_path("$RealBin/../..");
my $program = "$root/bin/fugubench";
my $script  = "$root/scripts/deps";
my $ftp     = "$root/scripts/ftp";

# Fugu::Process gives a child the named environment alone, and CI
# reaches the installed Fugu through PERL5LIB. Every child of this
# test therefore carries it.
my %LIB = defined $ENV{PERL5LIB} ? ( PERL5LIB => $ENV{PERL5LIB} ) : ();

# The rule holds until Tooling retires the script.
plan skip_all => 'scripts/deps is absent' unless -f $script;
plan skip_all => 'scripts/ftp is absent'  unless -x $ftp;

# The ftp helper of the script reads uname and runs the downloader of
# the platform. The stub gives the name of this host, so the helper
# takes the branch of this host, and the stub of that branch answers.
my $sysname = ( uname() )[0];
plan skip_all => "the ftp helper knows no downloader for $sysname"
    unless grep { $_ eq $sysname } qw(Darwin Linux OpenBSD);

my @ENVIRONMENTS = qw(tool runtime test develop);
my @OS           = qw(Darwin Linux OpenBSD);
my @ARCH         = qw(x86_64 arm64);

my $tree = tempdir( CLEANUP => 1 );
my $home = "$tree/home";
my $tmp  = "$tree/tmp";
my $path = "$tree/bin";
my $with = "$tree/cpanm-bin";
make_path( $home, $tmp, $path, $with );

# The stub tools. PATH holds these alone, so no cpanm resolves, and
# no downloader reaches a server.
for my $dir ( $path, $with ) {
	_stub( $dir, 'uname', "printf '%s\\n' '$sysname'" );
	_stub( $dir, $_, 'exit 0' ) for qw(curl wget ftp);
}
_stub( $with, 'cpanm', 'exit 0' );

# _stub($dir, $name, $body):
#	Write one stub command, and make it executable.
sub _stub ( $dir, $name, $body )
{
	Fugu::File->write( "$dir/$name", "#!/bin/sh\n$body\n" )
	    or die "write $dir/$name";
	chmod 0755, "$dir/$name" or die "chmod $dir/$name";

	return;
}

# _fixtures():
#	Each consumer fixture directory, in sorted order. A consumer
#	fixture holds a deps/ directory, and the tier fixtures of
#	t/fugubench/deps-tier.t hold none.
sub _fixtures ()
{
	opendir my $dh, "$RealBin/deps" or die 'the fixtures are absent';
	my @names = sort grep { !m{\A[.]} && -d "$RealBin/deps/$_/deps" }
	    readdir $dh;
	closedir $dh;

	return map { "$RealBin/deps/$_" } @names;
}

# _lines($text):
#	The trace lines of one run, with the helper path and each
#	temporary directory replaced by one token.
sub _lines ($text)
{
	my @lines = grep { index( $_, '+ ' ) == 0 } split /\n/, $text;
	for my $line (@lines) {
		$line =~ s{\Q$ftp\E}{fugubench fetch}g;
		$line =~ s{\Q$tmp\E/\S+?(?=/|\s|\z)}{TMP}g;
	}

	return \@lines;
}

# _script($dir, $bin, @argv):
#	Run scripts/deps in one fixture directory.
sub _script ( $dir, $bin, @argv )
{
	return _child( $bin, [ $^X, $script, @argv ], $dir );
}

# _verb($dir, $bin, @argv):
#	Run the deps verb against one fixture directory.
sub _verb ( $dir, $bin, @argv )
{
	return _child( $bin,
		[ $^X, "-I$root/lib", $program, '-C', $dir, 'deps', @argv ] );
}

# _child($bin, $cmd, $cwd):
#	Run one child with the stub PATH of $bin, and return the
#	result of Fugu::Process->run.
sub _child ( $bin, $cmd, $cwd = undef )
{
	my $result = Fugu::Process->run(
		cmd => $cmd,
		env => { PATH => $bin, HOME => $home, TMPDIR => $tmp, %LIB },
		defined $cwd ? ( cwd => $cwd ) : (),
	);
	die "cannot run $cmd->[1]: $result->{error}\n"
	    if defined $result->{error};

	return $result;
}

# _pair($dir, $name, $bin, @argv):
#	Compare the two traces of one case, and report the number of
#	trace lines.
sub _pair ( $dir, $name, $bin, @argv )
{
	my $one = _script( $dir, $bin, '--dry-run', @argv );
	my $two = _verb( $dir, $bin, '--dry-run', @argv );

	is(
		( $two->{exit_code} == 0 ? 1 : 0 ),
		( $one->{exit_code} == 0 ? 1 : 0 ),
		"$name: the verb and the script agree on the outcome"
	);
	my $want = _lines( $one->{stdout} );
	is_deeply( _lines( $two->{stdout} ), $want, "$name: the trace" );

	return scalar @$want;
}

my @fixtures = _fixtures();
is( scalar @fixtures, 13, 'the fixtures hold the thirteen consumers' );

my %seen;
my $lines = 0;
for my $dir (@fixtures) {
	my $fixture = ( split m{/}, $dir )[-1];
	for my $env (@ENVIRONMENTS) {
		for my $os (@OS) {
			for my $arch (@ARCH) {
				my $name = "$fixture $env $os $arch";
				my $count = _pair( $dir, $name, $path, '--os',
					$os, '--arch', $arch, $env );
				$lines += $count;
				$seen{$name} = 1 if $count;
			}
		}
	}
}

# One pair runs with a stub cpanm on PATH, where the trace names the
# bare command in place of the bootstrap.
{
	my ($dir) = grep { m{/FuguVM\z} } @fixtures;
	my $count = _pair( $dir, 'FuguVM runtime Darwin arm64 with cpanm',
		$with, '--os', 'Darwin', '--arch', 'arm64', 'runtime' );
	ok( $count > 0, 'the pair with a stub cpanm holds a trace' );
}

# The oracle must not pass on empty traces alone.
note "the matrix holds $lines trace lines in "
    . scalar( keys %seen )
    . ' cases';
ok( scalar( keys %seen ) >= 100, 'at least 100 cases hold a trace' );
ok( $lines >= 500,               'the matrix holds at least 500 lines' );

done_testing();
