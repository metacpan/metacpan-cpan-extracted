#!/usr/bin/env perl

# script/bi-geocode, run as a reader runs it: its arguments, how it opens a
# path: spec, and --col repeated for a place written across columns.  Every run
# is --offline and --dry-run, so nothing is sent anywhere and nothing is kept.
#
#   prove -l t/bi-geocode.t

use strict;
use warnings;

use Test::Most;
use File::Spec ();
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

my $script = File::Spec->catfile('script', 'bi-geocode');
plan skip_all => "$script is not here" unless -f $script;

my $dir   = tempdir(CLEANUP => 1);
my $model = tempdir(CLEANUP => 1);

my $csv = File::Spec->catfile($dir, 'houses.csv');
open(my $fh, '>', $csv) or BAIL_OUT("Cannot write $csv: $!");
print {$fh} "id,person,address,country\n",
	"1,Valentin,\"Brezje 8, Cerknica\",Slovenia\n",
	"2,Franc,,Slovenia\n";
close($fh) or BAIL_OUT("Cannot close $csv: $!");

# run(@args) -> ($exit, $output): stdout and stderr together.
sub run {
	my @args = @_;
	my $err = gensym;
	my $pid = open3(my $in, my $out, $err, $^X, '-Ilib', $script,
		'--data-dir', $dir, '--model-dir', $model, '--offline', '--dry-run', @args);
	close $in;
	my $output = do { local $/; join '', (<$out> // ''), (<$err> // '') };
	waitpid($pid, 0);
	return ($? >> 8, $output);
}

subtest 'a path: spec opens the file it names' => sub {
	my ($exit, $out) = run('--spec', "path:$csv", '--col', 'address', '--verbose');
	is($exit, 0, 'it runs') or diag $out;
	like($out, qr/Loaded 2 records/, 'and reads the file, whose name has an extension');
	unlike($out, qr/no records loaded|could not open/, 'not a table named after the whole file name');
};

subtest '--col repeated names a place across columns' => sub {
	my ($exit, $out) = run('--spec', "path:$csv", '--col', 'address', '--col', 'country', '--verbose');
	is($exit, 0, 'two columns run') or diag $out;
	like($out, qr{Resolved \d+/2 distinct places}, 'the rows are two distinct places: their cells joined');

	($exit, $out) = run('--spec', "path:$csv", '--col', 'address', '--col', 'nope');
	is($exit, 1, 'a second column that is not there stops it');
	like($out, qr/column "nope" not found/, 'and says which');
};

subtest '--text is added to the end of each place' => sub {
	my ($exit, $out) = run('--spec', "path:$csv", '--col', 'country', '--text', ' , Europe ', '--verbose');
	is($exit, 0, 'it runs') or diag $out;
	like($out, qr/Each place ends ", Europe"/, 'tidied as the map tidies it: no leading comma or spaces');
	like($out, qr{Resolved \d+/1 distinct places}, 'one place, Slovenia, Europe');

	($exit, $out) = run('--spec', "path:$csv", '--col', 'country', '-t', 'Europe', '--verbose');
	is($exit, 0, '-t is short for it') or diag $out;
	like($out, qr/Each place ends ", Europe"/, 'with the same text');

	($exit, $out) = run('--spec', "path:$csv", '--col', 'country', '--text', '  ', '--verbose');
	is($exit, 0, 'spaces are no text');
	unlike($out, qr/Each place ends/, 'so nothing is added');

	for my $bad ("Europe\nAsia", 'x' x 201) {
		($exit, $out) = run('--spec', "path:$csv", '--col', 'country', '--text', $bad);
		is($exit, 2, 'more than one short line is a usage error');
		like($out, qr/--text .*one line of at most 200 characters/, 'which says so');
	}
};

subtest 'the arguments it needs' => sub {
	my ($exit, $out) = run('--spec', "path:$csv");
	is($exit, 2, 'no --col is a usage error');
	like($out, qr/--col <column> is required/, 'which says so');

	($exit, $out) = run('--spec', "path:$csv", '--col', '');
	is($exit, 2, 'and an empty one is no column');
};

done_testing();
