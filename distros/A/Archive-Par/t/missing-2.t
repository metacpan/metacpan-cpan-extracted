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

use constant TESTPAR1 => 'mungo.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 24,
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

ok $files[0], 'mungo.1', 'Files in par (2)';
ok $files[1], 'mungo.2', 'Files in par (3)';
ok $files[2], 'mungo.3', 'Files in par (4)';
ok $files[3], 'mungo.4', 'Files in par (5)';
ok $files[4], 'mungo.5', 'Files in par (6)';

# -------------------------------------

=head2 Tests 10--11: Files Found by par

(1) Check that mungo.1 is found, as per $par
(2) Check that mungo.4 is not found, as per $par

=cut

ok $par->file_found('mungo.1');
ok ! $par->file_found('mungo.4');

# -------------------------------------

=head2 Tests 12--13: Files OK by par

(1) Check that mungo.2 is ok, as per $par
(2) Check that mungo.5 is not ok, as per $par

=cut

ok $par->file_ok('mungo.2');
ok ! $par->file_ok('mungo.5');

# -------------------------------------

=head2 Tests 14--16: Files Restorable by par

(1) Check that mungo.5 is not restorable, as per $par
(2) Check that mungo.3 is not restorable, as per $par
(3) Check that mungo.1 is not restorable, as per $par

=cut

ok ! $par->file_restorable('mungo.5');
ok ! $par->file_restorable('mungo.3');
ok ! $par->file_restorable('mungo.1');

# -------------------------------------


=head2 Tests 17--19: Files Corrupt by par

(1) Check that mungo.1 is not restorable, as per $par
(2) Check that mungo.2 is not restorable, as per $par
(2) Check that mungo.4 is not restorable, as per $par

=cut

ok ! $par->file_corrupt('mungo.1');
ok ! $par->file_corrupt('mungo.2');
ok ! $par->file_corrupt('mungo.4');

# -------------------------------------

=head2 Tests 20--21: Files moved by par

(1) Check that mungo.3 hasn't been found elsewhere by par
(2) Check that mungo.4 hasn't been found elsewhere by par

=cut

ok $par->file_moved('mungo.3'), undef, 'Files moved by par (1)';
ok $par->file_moved('mungo.4'), undef, 'Files moved by par (2)';

# -------------------------------------

=head2 Tests 22--23: Files not recoverable

Tests that the given files are not individually recoverable, allegedly.

(1) mungo.4
(2) mungo.5

=cut

ok ! $par->file_recoverable('mungo.4');
ok ! $par->file_recoverable('mungo.5');

# -------------------------------------

=head2 Test 24: File Not Recoverable

Tests that the Archive::Par instance reports recoverable to be false.

=cut

ok ! $par->recoverable;

# -------------------------------------
