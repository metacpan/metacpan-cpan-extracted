#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The program fuguseed-qr (QR-PROGRAM, QR-MNEMONIC-4, SEC-CHANNELS).
# The tests run bin/fuguseed-qr as a child, and they hold each of the
# three streams and the exit code. t/fuguseed/trust.t holds the module
# set of the program, and it scans each source (SEC-TRUST-3).

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use IPC::Open3       qw(open3);
use Symbol           qw(gensym);
use FindBin          qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

use constant PROGRAM => 'bin/fuguseed-qr';
use constant OUTPUT  => 't/fuguseed/fixtures/qr/vector4.output';

# Test vector 4 of the SeedQR specification.
use constant VECTOR =>
    'forum undo fragile fade shy sign arrest garment culture tube off merit';

# The child gets no PERL5LIB and no PERL5OPT of this environment, so
# no module comes from outside this checkout.
delete local @ENV{qw(PERL5LIB PERL5OPT)};

# _slurp($path):
#	The whole file as text.
sub _slurp ($path)
{
	open my $fh, '<', $path or BAIL_OUT("$path: $!");
	local $/ = undef;
	my $text = <$fh>;
	close $fh or BAIL_OUT("close $path: $!");

	return $text;
}

# _run($input, @argument):
#	Run the program with $input on standard input. The result is
#	the standard output, the standard error, and the exit code.
sub _run ( $input, @argument )
{
	local $SIG{PIPE} = 'IGNORE';
	my $fault = gensym;
	my $pid = open3( my $in, my $out, $fault, $^X, '-Ilib', PROGRAM,
		@argument );

	print {$in} $input or BAIL_OUT('the child takes no input');
	close $in;

	local $/ = undef;
	my $output = <$out>;
	my $error  = <$fault>;
	waitpid $pid, 0;
	my $status = $? >> 8;
	close $out;
	close $fault;

	return ( $output // q{}, $error // q{}, $status );
}

# QR-PROGRAM-3 and QR-PROGRAM-4: the words on standard input give the
# SeedQR on standard output.
my ( $output, $error, $status ) = _run( VECTOR . "\n" );
is( $output, _slurp(OUTPUT), 'test vector 4 gives the fixture output' );
is( $error,  q{},            'test vector 4 writes nothing to standard error' );
is( $status, 0,              'test vector 4 exits 0' );

# QR-PROGRAM-3: a run of spaces and tabs separates two words, and the
# program ignores them at the start and at the end of the line.
( my $tabbed = VECTOR ) =~ tr/ /\t/;
my ( $spaced, $quiet, $exit ) = _run(" \t$tabbed \t\n");
is_deeply(
	[ $spaced, $quiet, $exit ],
	[ _slurp(OUTPUT), q{}, 0 ],
	'runs of spaces and tabs separate the words'
);

# QR-PROGRAM-2: an argument is a usage error (D-12).
my ( $none, $usage, $code ) = _run( q{}, 'build' );
is( $none, q{}, 'an argument gives no standard output' );
is( $usage, "usage: fuguseed-qr\n", 'an argument gives one usage line' );
is( $code, 2, 'an argument exits 2' );

# QR-PROGRAM-4 and SEC-CHANNELS-2: a failure names the position, and
# standard error carries no word.
my @words = split q{ }, VECTOR;
$words[4] = 'blorp';
my ( $empty, $line, $failure ) = _run( "@words\n" );
my @named = grep { $line =~ /\b\Q$_\E\b/ } @words;
is( $empty, q{}, 'a wrong word gives no standard output' );
is( $line, "fuguseed-qr: word 5 is not in the word list\n",
	'a wrong word gives one line that names the position' );
is( "@named", q{}, 'the failure line holds no word of the input' );
is( $failure, 1, 'a wrong word exits 1' );

my ( $short, $count, $state ) = _run("forum undo\n");
is( $count, "fuguseed-qr: the input holds 2 words, not 12\n",
	'a wrong count gives one line that names the count' );
is( $short, q{}, 'a wrong count gives no standard output' );
is( $state, 1,   'a wrong count exits 1' );

# QR-MNEMONIC-4: a wrong checksum is a failure. "mercy" sits in the
# BLUE row of "merit", so the typed word changes the checksum alone.
my @typed = split q{ }, VECTOR;
$typed[-1] = 'mercy';
my ( $silent, $checksum, $result ) = _run( "@typed\n" );
is( $silent, q{}, 'a wrong checksum gives no standard output' );
is( $checksum, "fuguseed-qr: the checksum of the 12 words fails\n",
	'a wrong checksum gives one line that names no word' );
is( $result, 1, 'a wrong checksum exits 1' );

done_testing();
