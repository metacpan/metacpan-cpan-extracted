#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The conventions that no tool enforces: the pragma block of the
# floor, the Fugu module set of CLI-FUGU-1, and the boundary of the
# App:: namespace.
#
# The scan covers the files that this repository owns. A file that a
# pack of FuguBSD/Tooling owns carries the sync marker, and Tooling
# holds it to its own floor.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use File::Find ();
use FindBin    qw($RealBin);

my $root = "$RealBin/../..";

# The four lines of the pragma block, in order. The floor is perl
# 5.34, and that version needs the four lines.
my @PRAGMA = (
	'use v5.34;',
	'use warnings;',
	q{use experimental 'signatures';},
	'no feature qw(indirect multidimensional bareword_filehandles);',
);

# The Fugu modules that CLI-FUGU-1 names, and the lead module Fugu,
# which holds no code and carries the version of the library.
my %FUGU = map { $_ => 1 } qw(
    Fugu
    Fugu::CLI
    Fugu::Curl
    Fugu::Ed25519
    Fugu::File
    Fugu::Log
    Fugu::Process
    Fugu::Sandbox
    Fugu::Signify
);

# _read($path):
#	The lines of one file, without the line separators.
sub _read ($path)
{
	open my $fh, '<', $path or do {
		fail("$path is readable");
		return ();
	};
	my @lines = <$fh>;
	close $fh;
	chomp @lines;

	return @lines;
}

# _sources():
#	Every source that this repository owns: the executable, every
#	module under lib/, and every test under t/.
sub _sources ()
{
	my @files = ("$root/bin/fugubench");
	File::Find::find(
		sub {
			push @files, $File::Find::name
			    if -f $_ && /[.](?:pm|t)\z/;
		},
		"$root/lib",
		"$root/t"
	);

	return sort @files;
}

# _first(\@lines, $re):
#	The number of the first line that matches, or -1.
sub _first ( $lines, $re )
{
	for my $i ( 0 .. $#$lines ) {
		return $i if $lines->[$i] =~ $re;
	}

	return -1;
}

my @sources = _sources();
ok( @sources >= 4, 'the scan finds the sources of this repository' );

for my $path (@sources) {
	my $name = $path =~ s{\A\Q$root\E/}{}r;
	my @lines = _read($path);
	next if grep { index( $_, 'owns this file' ) >= 0 } @lines;

	# The pragma block: the four lines, in order, one after the
	# other
	my @at = map { _first( \@lines, qr/\A\Q$_\E\z/ ) } @PRAGMA;
	my $order = $at[0] >= 0;
	for my $i ( 1 .. $#at ) {
		$order = 0 unless $at[$i] == $at[ $i - 1 ] + 1;
	}
	ok( $order, "$name holds the four pragma lines in order" );

	# The package line, before the block. Perl::Critic reports a
	# pragma other than the version one before it, so a module
	# opens with the package and the block follows.
	my $package = _first( \@lines, qr/\Apackage\s/ );
	ok(
		$package < 0 || $package < $at[0],
		"$name opens its package before the pragma block"
	);

	next unless $name =~ m{\Alib/};

	# The Fugu module set, and the boundary of the namespace
	my @fugu = map { /\A\s*use\s+(Fugu(?:::\w+)*)\b/ ? $1 : () } @lines;
	my @stray = grep { !$FUGU{$_} } @fugu;
	is( "@stray", q{}, "$name uses the Fugu modules of CLI-FUGU-1" );

	my @app = map { /\A\s*use\s+(App::[\w:]+)/ ? $1 : () } @lines;
	my @outside = grep { !m{\AApp::FuguBench(?:::|\z)} } @app;
	is( "@outside", q{}, "$name uses no other App:: distribution" );

	my @copy = grep { /\Apackage\s+Fugu::/ } @lines;
	is( "@copy", q{}, "$name holds no copy of a Fugu module" );
}

done_testing();
