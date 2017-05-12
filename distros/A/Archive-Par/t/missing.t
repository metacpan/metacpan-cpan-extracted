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

use constant TESTPAR1 => 'baz.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 23,
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

=head2 Tests 4--8: Files in par

Check that each file in the par is as expected

(1) There are 4 files found
(2--5) The files are each as expected (looking through the return value of 
files)

=cut

$par->check;

my @files = sort $par->files;
ok @files, 4, 'Files in par (1)';

ok $files[0], 'baz.1', 'Files in par (2)';
ok $files[1], 'baz.2', 'Files in par (3)';
ok $files[2], 'baz.3', 'Files in par (4)';
ok $files[3], 'baz.4', 'Files in par (5)';

# -------------------------------------

=head2 Tests 9--10: Files Found by par

(1) Check that baz.1 is found, as per $par
(2) Check that baz.4 is not found, as per $par

=cut

ok $par->file_found('baz.1');
ok ! $par->file_found('baz.4');

# -------------------------------------

=head2 Tests 11--12: Files OK by par

(1) Check that baz.1 is ok, as per $par
(2) Check that baz.2 is not ok, as per $par

=cut

ok $par->file_ok('baz.1');
ok ! $par->file_ok('baz.2');

# -------------------------------------

=head2 Tests 13--15: Files Restorable by par

(1) Check that baz.1 is not restorable, as per $par
(2) Check that baz.3 is not restorable, as per $par

=cut

ok ! $par->file_restorable('baz.1');
ok ! $par->file_restorable('baz.2');
ok ! $par->file_restorable('baz.3');

# -------------------------------------


=head2 Tests 16--18: Files Corrupt by par

(1) Check that baz.1 is not restorable, as per $par
(2) Check that baz.3 is not restorable, as per $par

=cut

ok ! $par->file_corrupt('baz.1');
ok ! $par->file_corrupt('baz.2');
ok ! $par->file_corrupt('baz.3');

# -------------------------------------

=head2 Tests 19--20: Files moved by par

(1) Check that baz.3 hasn't been found elsewhere by par
(2) Check that baz.4 hasn't been found elsewhere by par

=cut

ok $par->file_moved('baz.3'), undef, 'Files moved by par (1)';
ok $par->file_moved('baz.4'), undef, 'Files moved by par (2)';

# -------------------------------------

=head2 Tests 21--22: Files not recoverable

Tests that the given files are not individually recoverable, allegedly.

(1) baz.2
(2) baz.4

=cut

ok ! $par->file_recoverable('baz.2');
ok ! $par->file_recoverable('baz.4');

# -------------------------------------

=head2 Test 23: File Not Recoverable

Tests that the Archive::Par instance reports recoverable to be false.

=cut

ok ! $par->recoverable;

# -------------------------------------
