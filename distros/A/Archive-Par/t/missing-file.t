# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Archive::Par

This package tests the handling of pars with missing source files of
Archive::Par.

=cut

use File::Compare          1.1002 qw( cmp );
use File::Spec::Functions         qw( catfile rel2abs);
use FindBin                  1.42 qw( $Bin );
use Test                     1.13 qw( ok plan skip );

use lib $Bin;

use test qw( DATA_DIR REF_DIR
             evcheck );

use constant TESTPAR1 => 'foo.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 27,
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

=head2 Tests 4--9: Files in par

Check that each file in the par is as expected

(1) There are 5 files found
(2--6) The files are each as expected (looking through the return value of 
files)

=cut

$par->check;

my @files = sort $par->files;
ok @files, 5, 'Files in par (1)';

ok $files[0], 'foo.1', 'Files in par (2)';
ok $files[1], 'foo.2', 'Files in par (3)';
ok $files[2], 'foo.3', 'Files in par (4)';
ok $files[3], 'foo.4', 'Files in par (5)';
ok $files[4], 'foo.5', 'Files in par (6)';

# -------------------------------------

=head2 Tests 10--11: Files Found by par

(1) Check that foo.1 is found, as per $par
(2) Check that foo.4 is not found , as per $par

=cut

ok $par->file_found('foo.1');
ok ! $par->file_found('foo.4');

# -------------------------------------

=head2 Tests 12--13: Files OK by par

(1) Check that foo.1 is ok, as per $par
(2) Check that foo.4 is not ok, as per $par

=cut

ok $par->file_ok('foo.1');
ok ! $par->file_ok('foo.4');

# -------------------------------------

=head2 Tests 14--15: Files Restorable by par

(1) Check that foo.1 is not restorable, as per $par
(2) Check that foo.4 is restorable, as per $par

=cut

ok ! $par->file_restorable('foo.1');
ok $par->file_restorable('foo.4');

# -------------------------------------

=head2 Test 16: File not OK

Tests that the Archive::Par instance reports ok to be false.

=cut

ok ! $par->ok;

# -------------------------------------

=head2 Test 17: File Checked

Tests that the Archive::Par instance reports checked to be true.

=cut

ok $par->checked;

# -------------------------------------

=head2 Test 18: File Recoverable

Tests that the Archive::Par instance reports recoverable  to be true.

=cut

ok $par->recoverable;

# -------------------------------------

=head2 Test 19: File recoverable

Tests that the given files are not individually recoverable, allegedly.

(1) foo.4

=cut

ok $par->file_recoverable('foo.4');

# -------------------------------------

=head2 Test 20--27: Restore File

Attempts to restore from the par file

(1) Check no exception thrown
(2--6) Check that all files are now ok
(7) Check that foo.4 really exists
(8) Check that foo.4 matches that in testref

=cut

my $foo4  = catfile DATA_DIR, 'foo.4';
my $tfoo4 = catfile REF_DIR,  'foo.4';

my $skip = ! -w DATA_DIR;

skip $skip, evcheck(sub { $par->restore }, 'Restore File (1)'), 
            1, 'Restore File (1)';
skip $skip, $par->file_ok(sprintf "foo.%d", $_)
  for (1..5);
skip $skip, -e $foo4;
skip $skip, cmp($foo4, $tfoo4), 0, 'Restore File (8)';
unlink $foo4;

# -------------------------------------
