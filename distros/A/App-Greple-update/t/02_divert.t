use v5.14;
use warnings;

use Test::More;
use File::Temp qw(tempfile);

use App::Greple::update;

# While the output is diverted for --update, STDOUT must stay a real
# file descriptor: a command that greple runs meanwhile (through -Mtee,
# for example) writes to it, and Command::Run dups it.  An in-memory
# handle has no descriptor, and the child output goes nowhere.

my($tmp, $file) = tempfile(UNLINK => 1);
close $tmp;
open my $save, '>&', \*STDOUT or die "dup: $!";
open STDOUT, '>', $file or die "open: $!";

App::Greple::update::update_divert();
my $fd = fileno(STDOUT);
print "diverted\n";
App::Greple::update::recover_stdout();
print "after\n";

close STDOUT;
open STDOUT, '>&', $save or die "restore: $!";

ok(defined $fd && $fd >= 0,
   sprintf 'STDOUT keeps a real file descriptor while diverted (fileno %s)', $fd // 'undef');
open my $fh, '<', $file or die;
my $written = do { local $/; <$fh> };
is($written, "after\n", 'diverted output stays out of STDOUT, later output reaches it');

done_testing;
