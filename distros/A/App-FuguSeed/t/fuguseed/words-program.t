#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The program fuguseed-words (WORDS-PROGRAM, WORDS-BUILD-1,
# WORDS-CHECK-1, WORDS-CHECK-2, SEC-TRUST-1, TEST-PACK-3).
# The tests run bin/fuguseed-words as a child, and they hold each of
# the three streams and the exit code. The last part proves that no
# module of the program loads App::FuguSeed::Mnemonic.
#
# The child keeps the environment of this process. fuguseed-words
# builds on the Fugu library (D-06), and an installed library can sit
# on PERL5LIB.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Temp ();
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);
use FindBin    qw($RealBin);

my $root = "$RealBin/../..";
chdir $root or BAIL_OUT("chdir $root: $!");

plan skip_all => 'the Fugu library is absent'
    unless eval { require Fugu::CLI; 1 };

use constant PROGRAM => 'bin/fuguseed-words';
use constant LIST    => 'share/fuguseed/english.txt';
use constant FIXTURE => 't/fuguseed/fixtures/sheet.html';
use constant DATE    => '2026-01-01';

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

# _run(@argument):
#	Run the program with @argument and no standard input. The
#	result is the standard output, the standard error, and the
#	exit code.
sub _run (@argument)
{
	my $fault = gensym;
	my $pid   = open3( my $in, my $out, $fault, $^X, '-Ilib', PROGRAM,
		@argument );
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

# WORDS-PROGRAM-3: --help prints the usage on standard output and it
# exits 0.
my ( $help, $quiet, $status ) = _run('--help');
like( $help, qr/\Ausage: fuguseed-words <command>/,
	'--help prints the usage line' );
like( $help, qr/^\s+build\s/m,  '--help names the build verb' );
like( $help, qr/^\s+check\s/m,  '--help names the check verb' );
is( $quiet,  q{},               '--help writes nothing to standard error' );
is( $status, 0,                 '--help exits 0' );

for my $verb (qw(build check)) {
	my ( $usage, $silent, $code ) = _run( $verb, '--help' );
	like( $usage, qr/\Ausage: fuguseed-words $verb /,
		"$verb --help prints the usage line of the verb" );
	is( $silent, q{}, "$verb --help writes nothing to standard error" );
	is( $code,   0,   "$verb --help exits 0" );
}

# WORDS-PROGRAM-2 and WORDS-PROGRAM-3: a command line without a verb
# is a usage error, and so is an unknown verb.
my ( $none, $line, $code ) = _run();
is( $none, q{}, 'no verb gives no standard output' );
is( $line, "usage: fuguseed-words <command> [arguments]\n",
	'no verb gives one usage line on standard error' );
is( $code, 2, 'no verb exits 2' );

my ( $empty, $unknown, $state ) = _run('print');
is( $empty, q{}, 'an unknown verb gives no standard output' );
like( $unknown, qr/unknown command: print/,
	'an unknown verb names the verb on standard error' );
is( $state, 2, 'an unknown verb exits 2' );

# WORDS-BUILD-1: the list argument is required.
my ( $no_list, $build_usage, $build_code ) = _run('build');
is( $no_list, q{}, 'build without a list gives no standard output' );
is( $build_usage, "usage: fuguseed-words build <list> [--date YYYY-MM-DD]\n",
	'build without a list gives the usage line of the verb' );
is( $build_code, 2, 'build without a list exits 2' );

# WORDS-BUILD-1 and WORDS-BUILD-7: the build writes the sheet to
# standard output, and it writes no diagnostic.
my ( $sheet, $stderr, $build ) = _run( 'build', '--date', DATE, LIST );
is( $sheet,  _slurp(FIXTURE), 'build writes the sheet of the fixture' );
is( $stderr, q{},             'build writes nothing to standard error' );
is( $build,  0,               'build exits 0' );

my ( $nothing, $date_error, $date_code ) =
    _run( 'build', '--date', '2026-1-1', LIST );
is( $nothing, q{}, 'a malformed date gives no standard output' );
like( $date_error, qr/the date must read YYYY-MM-DD/,
	'a malformed date names the form' );
is( $date_code, 2, 'a malformed date exits 2' );

# LIST-SHARE-3: a list with another digest is a failure, not a usage
# error, and the diagnostic leaves on standard error.
my $other = File::Temp->new;
print {$other} "abandon\nability\n"
    or BAIL_OUT('the temporary file takes no text');
$other->flush;
my ( $refused, $refusal, $refusal_code ) =
    _run( 'build', '--date', DATE, $other->filename );
is( $refused, q{}, 'a list with another digest gives no standard output' );
like( $refusal, qr/is not the English word list of BIP39/,
	'a list with another digest names the refusal' );
is( $refusal_code, 1, 'a list with another digest exits 1' );

# WORDS-CHECK-1 and WORDS-CHECK-2: the check is silent on success.
my ( $said, $reported, $check ) = _run( 'check', FIXTURE, LIST );
is( $said,     q{}, 'check writes nothing to standard output' );
is( $reported, q{}, 'check writes nothing to standard error' );
is( $check,    0,   'check exits 0' );

my ( $check_none, $check_usage, $check_code ) = _run( 'check', FIXTURE );
is( $check_none, q{}, 'check without a list gives no standard output' );
is( $check_usage, "usage: fuguseed-words check <sheet> <list>\n",
	'check without a list gives the usage line of the verb' );
is( $check_code, 2, 'check without a list exits 2' );

# WORDS-CHECK-2: a corrupted sheet gives one line for each defect on
# standard error, and it exits 1.
my $corrupt = File::Temp->new;
my $text    = _slurp(FIXTURE) =~ s{<td>able</td>}{<td>ability</td>}r;
print {$corrupt} $text or BAIL_OUT('the temporary file takes no sheet');
$corrupt->flush;
my ( $mute, $defects, $failure ) =
    _run( 'check', $corrupt->filename, LIST );
is( $mute, q{}, 'a corrupted sheet gives no standard output' );
like( $defects,
	qr/YELLOW 1 BLUE 1 RED 3: the sheet holds ability, and the list holds able/,
	'a corrupted sheet names the position of the cell' );
is( scalar( () = $defects =~ /\n/g ), 2, 'each defect holds one line' );
is( $failure, 1, 'a corrupted sheet exits 1' );

my ( $absent, $unreadable, $absent_code ) =
    _run( 'check', 't/fuguseed/no-such-sheet.html', LIST );
is( $absent, q{}, 'a sheet that no file holds gives no standard output' );
like( $unreadable, qr/cannot read the sheet/,
	'a sheet that no file holds names the failure' );
is( $absent_code, 1, 'a sheet that no file holds exits 1' );

# SEC-TRUST-1 and TEST-PACK-3: no module of the program loads
# App::FuguSeed::Mnemonic. The module list comes from the program
# itself: a child loads App::FuguSeed::Words and prints %INC, so a
# later module of the program joins the scan.
open my $ph, '-|', $^X, '-Ilib', '-MApp::FuguSeed::Words', '-e',
    'print "$_\n" for sort keys %INC'
    or BAIL_OUT("$^X: $!");
my @loaded = <$ph>;
close $ph or BAIL_OUT("close $^X: status $?");
chomp @loaded;

my @modules = grep { m{\AApp/FuguSeed/} } @loaded;
is( ( grep { $_ eq 'App/FuguSeed/Mnemonic.pm' } @modules ),
	0, 'the program loads no App::FuguSeed::Mnemonic' );

my @want = qw(
    App/FuguSeed/Check.pm
    App/FuguSeed/List.pm
    App/FuguSeed/ListFile.pm
    App/FuguSeed/Sheet.pm
    App/FuguSeed/Words.pm
);
my %loaded = map { $_ => 1 } @modules;
my @absent = grep { !$loaded{$_} } @want;
is( "@absent", q{}, 'the scan covers the program and its four modules' );

# The source scan holds the rule against a load that runs later, or
# that a condition hides. The pattern is the literal module name, so
# the word block of App::FuguSeed::List needs no strip.
for my $path ( PROGRAM, map { "lib/$_" } sort @modules ) {
	unlike( _slurp($path), qr/App::FuguSeed::Mnemonic/,
		"$path names no App::FuguSeed::Mnemonic" );
}

done_testing();
