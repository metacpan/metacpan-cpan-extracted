# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Archive::Par

This package tests the handling of pars with too many broken source files of
Archive::Par.

=cut


use File::Spec::Functions      qw( catfile rel2abs);
use FindBin               1.42 qw( $Bin );
use Test                  1.13 qw( ok plan );

use lib $Bin;

use test qw( DATA_DIR
             evcheck );

use constant TESTPAR1 => 'fob.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 21,
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

=head2 Tests 4--7: Files in par

Check that each file in the par is as expected

(1) There are 5 files found
(2--6) The files are each as expected (looking through the return value of 
files)

=cut

$par->check;

my @files = sort $par->files;
ok @files, 3, 'Files in par (1)';

ok $files[0], 'fob.1', 'Files in par (2)';
ok $files[1], 'fob.2', 'Files in par (3)';
ok $files[2], 'fob.3', 'Files in par (4)';

# -------------------------------------

=head2 Tests 8--9: Files Found by par

(1) Check that fob.1 is found, as per $par
(2) Check that fob.3 is found , as per $par

=cut

ok $par->file_found('fob.1');
ok $par->file_found('fob.3');

# -------------------------------------

=head2 Tests 10--11: Files OK by par

(1) Check that fob.1 is ok, as per $par
(2) Check that fob.3 is not ok, as per $par

=cut

ok $par->file_ok('fob.1');
ok ! $par->file_ok('fob.3');

# -------------------------------------

=head2 Tests 12--13: Files Restorable by par

(1) Check that fob.1 is not restorable, as per $par
(2) Check that fob.3 is not restorable, as per $par

=cut

ok ! $par->file_restorable('fob.1');
ok ! $par->file_restorable('fob.3');

# -------------------------------------


=head2 Tests 14--16: Files Corrupt by par

(1) Check that fob.1 is not restorable, as per $par
(2) Check that fob.3 is not restorable, as per $par

=cut

ok ! $par->file_corrupt('fob.1');
ok $par->file_corrupt('fob.2');
ok $par->file_corrupt('fob.3');

# -------------------------------------

=head2 Test 17: File not OK

Tests that the Archive::Par instance reports ok to be false.

=cut

ok ! $par->ok;

# -------------------------------------

=head2 Test 18: File Checked

Tests that the Archive::Par instance reports checked to be true.

=cut

ok $par->checked;

# -------------------------------------

=head2 Test 19: File not Recoverable

Tests that the Archive::Par instance reports recoverable to be false.

=cut

ok ! $par->recoverable;

# -------------------------------------

=head2 Tests 20--21: Files not recoverable

Tests that the given files are not individually recoverable, allegedly.

(1) fob.2
(2) fob.3

=cut

ok ! $par->file_recoverable('fob.2');
ok ! $par->file_recoverable('fob.3');
