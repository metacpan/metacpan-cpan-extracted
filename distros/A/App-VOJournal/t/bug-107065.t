#=============================================================================
#
# Bug #107065: Overwrites journal when called without '--resume'
#
# https://rt.cpan.org/Ticket/Display.html?id=107065
#
# This test uses the external program 'cat' instead of the editor vim to
# check whether App::VOJournal overwrites an existent journal file of
# the current day.
#
#=============================================================================

use strict;
use warnings FATAL => 'all';

use Test::More;
use File::Path qw(make_path remove_tree);

eval "use Probe::Perl";
if ($@) {
	plan skip_all => 'Probe::Perl required for testing the script';
}
elsif ('MSWin32' eq $^O) { # man perlport
	plan skip_all => qq(Script is not usable on $^O);
}
else {
	plan tests => 6;
}

my $basedir = 't/testbase';
my $journaldir = "$basedir/2015/02";
my $journalfile = "$journaldir/20150231.otl";
my $oldjournalfile = "$journaldir/20150230.otl";
my $perl = Probe::Perl->find_perl_interpreter;
my $script  = 'bin/vojournal';
my @scriptopts = (
	"--basedir=$basedir",
	'--date=20150231',
	'--editor=cat',
	'--noresume',	# 20160516: must add --noresume, since --resume is default
);
my $line;

diag("Testing #107065: Overwrites journal when called without '--resume'");

# first check: with option '--resume', no last file
#
setup();
$line = read_pipe($perl, '-Ilib', $script, @scriptopts, '--resume');
like($line, qr/^; 2015-02-31$/, "with --resume");

# second check: without option '--resume', no last file
#
setup();
$line = read_pipe($perl, '-Ilib', $script, @scriptopts);
like($line, qr/^; 2015-02-31$/, "without --resume");

# third check: with option '--resume', last file from same day
#
setup();
print_to("$journalfile","Test");
$line = read_pipe($perl, '-Ilib', $script, @scriptopts, '--resume');
like($line, qr/^Test$/, "with --resume");

# fourth check: without option '--resume', last file from same day
#
setup();
print_to("$journalfile","Test");
$line = read_pipe($perl, '-Ilib', $script, @scriptopts);
like($line, qr/^Test$/, "without --resume");

# fifth check: with option '--resume', last file from older day
#
setup();
print_to("$oldjournalfile","[x] a\n[_] b");
$line = read_pipe($perl, '-Ilib', $script, @scriptopts, '--resume');
like($line, qr/^; 2015-02-31.\[_] b$/s, "with --resume");

# sixth check: without option '--resume', last file from older day
#
setup();
print_to("$oldjournalfile","[x] a\n[_] b");
$line = read_pipe($perl, '-Ilib', $script, @scriptopts);
like($line, qr/^; 2015-02-31$/, "without --resume");

teardown();

sub print_to {
	my ($fpath,$text) = @_;
	if (open(my $OUT, '>', $fpath)) {
		print $OUT $text;
		close $OUT;
	}
	else {
		die "can't open $fpath for writing: $!";
	}
}

sub read_pipe {
	my $line = "";
	if (open(my $OUT, '-|', @_)) {
		local $/ = undef;
		$line = <$OUT>;
		close $OUT;
	}
	else {
		die "can't open pipe: $!";
	}
	chomp $line;
	return $line;
}

sub setup {
	remove_tree($basedir);
	make_path("$journaldir");
}

sub teardown {
	remove_tree($basedir);
}
