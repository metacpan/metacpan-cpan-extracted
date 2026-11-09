use strict;
use warnings;
use Test::More;

# GUARD: no test file of this distribution puts a sibling checkout of the core
# on @INC (karr k121).
#
# WHY: `use lib '../dbio/lib'` finds the core only where the DBIO family sits
# side by side and prove is started from the dist's root. In a git worktree
# there is no ../dbio, and the line then does nothing -- or, worse, loads a
# different core than the one `prove -l` / PERL5LIB / the installed one names.
# A test that needs the core gets it from the harness, not from a relative path.
#
# What this file claims: no line of code in t/*.t and t/lib/*.pm names
# ../dbio/lib (a line that is a comment is not code).

use File::Glob ();
use FindBin;
use DBIO::Util ();

my $t = $FindBin::Bin;
my @files = sort map { File::Glob::bsd_glob($_) } "$t/*.t", "$t/lib/*.pm";
cmp_ok scalar(@files), '>', 100, 'the test files of this distribution were found'
  or BAIL_OUT("no test files under $t");

my $SIBLING = qr{\.\./dbio/lib};   # written escaped, so this line does not match itself
my @found;
for my $path (@files) {
  my $n = 0;
  for my $line (split /\n/, DBIO::Util::slurp_file_utf8($path)) {
    $n++;
    next if $line =~ /^\s*#/;
    push @found, substr($path, length("$t/")) . ":$n" if $line =~ $SIBLING;
  }
}

is_deeply \@found, [], 'no test file puts a sibling core checkout on @INC'
  or diag "found at: @found";

done_testing;
