# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Archive::Par

This package tests the handling of pars with corrupt source files of
Archive::Par.

=cut

use File::Compare          1.1002 qw( cmp );
use File::Copy               2.03 qw( mv );
use File::Spec::Functions         qw( catfile rel2abs);
use FindBin                  1.42 qw( $Bin );
use Test                     1.13 qw( ok plan skip );

use lib $Bin;

use test qw( DATA_DIR REF_DIR
             evcheck );

use constant TESTPAR1 => 'bar.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 33,
       todo   => [],
}

use Archive::Par;

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

=head2 Tests 2--3: Archive::Par Creation

Create a new Archive::Par object, referring to DATA_DIR/test.par

(1) Test no exception thrown
(2) Test fn component matches

=cut

my $fn = catfile DATA_DIR, TESTPAR1;
my $par;
ok(evcheck(sub{ $par = Archive::Par->new($fn); }, 'Archive::Par Creation (1)'),
	 1, 'Archive::Par Creation (1)');
ok rel2abs($par->fn), rel2abs($fn), 'Archive::Par Creation (2)';

# -------------------------------------

=head2 Tests 4--11: Files in par

Check that each file in the par is as expected

(1) There are 7 files found
(2--8) The files are each as expected (looking through the return value of 
files)

=cut

$par->check;

my @files = sort $par->files;
ok @files, 7, 'Files in par (a1)';

for (1..7) {
  ok $files[$_-1], sprintf("bar.%d", $_), sprintf("Files in par (%d)", $_+1);
}

# -------------------------------------

=head2 Tests 12--13: Files OK by par

(1) bar.1 is okay
(2) bar.3 is not okay

=cut

ok $par->file_ok('bar.1');
ok ! $par->file_ok('bar.3');

# -------------------------------------

=head2 Tests 14--15: Files found by par

(1) bar.1 is found
(2) bar.3 is found

=cut

ok $par->file_found('bar.1');
ok $par->file_found('bar.3');

# -------------------------------------

=head2 Tests 16--17: Files restorable by par

(1) bar.1 is not restorable
(2) bar.3 is restorable

=cut

ok ! $par->file_restorable('bar.1');
ok $par->file_restorable('bar.3');

# -------------------------------------

=head2 Tests 18--19: Files corrupt by par

(1) bar.1 is not corrupt
(2) bar.3 is corrupt

=cut

ok ! $par->file_corrupt('bar.1');
ok $par->file_corrupt('bar.3');

# -------------------------------------

=head2 Test 20: File not OK

Tests that the Archive::Par instance reports ok to be false.

=cut

ok ! $par->ok;

# -------------------------------------

=head2 Test 21: File Checked

Tests that the Archive::Par instance reports checked to be true.

=cut

ok $par->checked;

# -------------------------------------

=head2 Test 22: File Recoverable

Tests that the Archive::Par instance reports recoverable  to be true.

=cut

ok $par->recoverable;

# -------------------------------------

=head2 Tests 23: Files recoverable

Tests that the given files are individually recoverable, allegedly.

(1) bar.3

=cut

ok $par->file_recoverable('bar.3');

# -------------------------------------

=head2 Test 24--33: Restore File

Attempts to restore from the par file

(1) Check no exception thrown
(2--8) Check that all files are now ok
(9) Check that foo.4 really exists
(10) Check that foo.4 matches that in testref

=cut

my $skip = ! -w DATA_DIR;

my $recover = catfile DATA_DIR, 'bar.3';
my $moved   = "$recover.bad";
my $checkfn = catfile REF_DIR,  'bar.3';
skip $skip, evcheck(sub { $par->restore }, 'Restore File (1)'),
            1, 'Restore File (1)';
skip $skip, $par->file_ok(sprintf "bar.%d", $_)
  for (1..7);
skip $skip, -e $recover;
skip $skip, cmp($recover, $checkfn), 0, 'Restore File (10)';
mv $moved, $recover;

# -------------------------------------
