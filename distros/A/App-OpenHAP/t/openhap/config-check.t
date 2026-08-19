#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The startup validation of openhapd: the daemon refuses a bad
# setup code, log level, or log facility before it detaches, and
# names the value. openhapd -n exercises exactly that path.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);

use Fugu::Process;

my $openhapd = "$RealBin/../../bin/openhapd";
my $dir      = tempdir( CLEANUP => 1 );
my $n        = 0;

# check($content): run openhapd -n over a config file that holds
#	$content, and return the run result.
sub check ($content)
{
	my $file = sprintf '%s/check%d.conf', $dir, $n++;
	open my $fh, '>', $file or die "Cannot write $file: $!";
	print {$fh} $content;
	close $fh;

	return Fugu::Process->run(
		cmd => [ $^X, "-I$RealBin/../../lib", $openhapd, '-n',
			'-c', $file ] );
}

subtest 'a valid configuration passes' => sub {
	my $r = check("hap_pin = 9876-5432\nlog_level = debug\n");
	is( $r->{exit_code}, 0, 'openhapd -n exits 0' );
	like( $r->{stdout}, qr/is valid/, 'and says so' );
};

subtest 'a trivial setup code fails, named' => sub {
	my $r = check("hap_pin = 000-00-000\n");
	is( $r->{exit_code}, 1, 'openhapd -n exits 1' );
	like( $r->{stderr}, qr/000-00-000/, 'the message names the value' );
};

subtest 'an unknown log level fails, named' => sub {
	my $r = check("log_level = err\n");
	is( $r->{exit_code}, 1, 'openhapd -n exits 1' );
	like( $r->{stderr}, qr/log_level "err"/,
		'the message names the value' );
	like( $r->{stderr}, qr/debug, info, notice, warning, error/,
		'and lists the accepted spellings' );
};

subtest 'an unknown log facility fails, named' => sub {
	my $r = check("log_facility = local9\n");
	is( $r->{exit_code}, 1, 'openhapd -n exits 1' );
	like( $r->{stderr}, qr/log_facility "local9"/,
		'the message names the value' );
};

subtest 'a documented facility passes' => sub {
	my $r = check("log_facility = local0\n");
	is( $r->{exit_code}, 0, 'local0 is accepted' );
};

done_testing();
