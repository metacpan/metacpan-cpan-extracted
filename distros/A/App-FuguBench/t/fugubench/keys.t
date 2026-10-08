#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The embedded release keys against deps/KEYS.txt (DIST-KEY).
#
# The org pack of FuguBSD/Tooling owns deps/KEYS.txt, and
# App::FuguBench::Keys carries the keys of that file into the packed
# program. These cases hold the module to the file, so a rotation of
# the pack that no release follows fails here.
#
# The file holds two line forms. A body line gives the key body, and
# a case compares it directly. A URL line gives the published key
# file and its sha256 digest. A signify public key file holds the
# comment line and the body and nothing else, so a case rebuilds
# that file from the pair and holds it to the digest. That case
# needs no network, and one wrong character of the body breaks it.
#
# A last case fetches the published file itself. It runs with
# FUGUBENCH_NETWORK set, and it skips without it, so `make test`
# reads no network.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Test::More;
use Digest::SHA ();
use File::Temp  qw(tempdir);
use FindBin     qw($RealBin);
use lib "$RealBin/../../lib";

use Fugu::Process;
use Fugu::Signify;

use App::FuguBench::Keys;

my $root = "$RealBin/../..";
my $file = "$root/deps/KEYS.txt";

# _read($path):
#	The whole text of one file.
sub _read ($path)
{
	open my $fh, '<', $path or do {
		fail("$path is readable");
		return q{};
	};
	local $/ = undef;
	my $text = <$fh>;
	close $fh;

	return $text;
}

# _sha256($path):
#	The sha256 digest of one file, in lower-case hex.
sub _sha256 ($path)
{
	open my $fh, '<', $path or die "cannot read $path: $!\n";
	binmode $fh;
	my $digest = Digest::SHA->new(256)->addfile($fh)->hexdigest;
	close $fh;

	return $digest;
}

# _lines($path):
#	The fields of every key line of one key file, in the order of
#	the file. A # starts a comment, and a blank line carries no
#	key. Two fields give the body form, and three give the URL
#	form (DEPS-KEYS-2).
sub _lines ($path)
{
	return map { [ split q{ } ] }
	    grep    { !/\A\s*(?:#|\z)/ } split /\n/, _read($path);
}

my @lines = _lines($file);
ok( @lines, 'deps/KEYS.txt holds a key line' );

my @pairs = App::FuguBench::Keys->keys;

# The module holds the keys of the file, in the trust order of the
# file: no key of the file is absent, and no pair holds a name that
# the file lacks (DIST-KEY-1).
is_deeply(
	[ map { $_->[0] } @pairs ],
	[ map { $_->[0] } @lines ],
	'the module holds the key names of the file, in that order'
);

# Every body is the second line of a signify public key file, so the
# parser of Fugu::Signify holds it to the 42 bytes of that form.
{
	my $signify = Fugu::Signify->new( engine => 'perl' );

	for my $pair (@pairs) {
		my ( $name, $body ) = @$pair;
		like(
			$body, qr{\A[A-Za-z0-9+/]{56}\z},
			"the body of $name holds 56 base64 characters"
		);

		my $text = "untrusted comment: $name public key\n$body\n";
		ok(
			$signify->parse_public_key($text),
			"the body of $name parses as a signify public key"
		) or diag $signify->error;
	}
}

# A body line carries the body itself, so the case needs no network.
for my $i ( 0 .. $#lines ) {
	my ( $name, $body, $digest ) = @{ $lines[$i] };
	next if defined $digest;

	is( $pairs[$i][1], $body, "the pair of $name holds the body of its line" );
}

# The URL form carries no body, and its digest is the trust anchor
# (DEPS-KEYS-2). The case rebuilds the published file from the name
# of the line and the body of the pair, and it holds the result to
# that digest (DIST-KEY-1).
for my $i ( 0 .. $#lines ) {
	my ( $name, undef, $digest ) = @{ $lines[$i] };
	next unless defined $digest;

	my $text = "untrusted comment: $name public key\n$pairs[$i][1]\n";
	is(
		Digest::SHA->new(256)->add($text)->hexdigest, $digest,
		"the pair of $name rebuilds the key file of its line"
	);
}

# The same anchor over the network: the case fetches the published
# file, holds it to the digest, and reads the body out of it.
subtest 'the published key file of each URL line' => sub {
	plan skip_all => 'set FUGUBENCH_NETWORK to read the network'
	    unless $ENV{FUGUBENCH_NETWORK};

	my @urls = grep { defined $lines[$_][2] } 0 .. $#lines;
	plan skip_all => 'deps/KEYS.txt holds no URL line' unless @urls;

	my $dir = tempdir( CLEANUP => 1 );
	for my $i (@urls) {
		my ( $name, $url, $digest ) = @{ $lines[$i] };

		my $out = "$dir/$name.pub";
		my $r   = Fugu::Process->run(
			cmd => [ 'curl', '-fsS', '-o', $out, $url ],
			env => { PATH => $ENV{PATH} // '/usr/bin:/bin' },
		);
		ok( $r->{success}, "curl fetches the key file of $name" )
		    or do { diag $r->{stderr}; next; };

		is( _sha256($out), $digest,
			"the key file of $name holds the digest of its line" );

		my @text = split /\n/, _read($out);
		is( $text[1], $pairs[$i][1],
			"the module holds the body of the key file of $name" );
	}
};

done_testing();
