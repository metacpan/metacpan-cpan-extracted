# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Archive::Par

This package tests the basic functionality of Archive::Par

=cut


use File::Spec::Functions      qw( catfile rel2abs);
use FindBin               1.42 qw( $Bin );
use Test                  1.13 qw( ok plan );

use lib $Bin;

use Archive::Par;
use test qw( DATA_DIR
             evcheck );

use constant TESTPAR1 => 'test.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 11,
       todo   => [],
}

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

=head2 Test 4: File not checked

Tests that the Archive::Par instance reports checked to be false

=cut

ok ! $par->checked;

# -------------------------------------

=head2 Test 5: Run check

Run C<< $par->check >>.  Check no exception thrown.

=cut

ok evcheck(sub { $par->check }, 'Run check'), 1, 'Run check';


# -------------------------------------

=head2 Tests 6--9: Files in par

(1) Check there are 3 files in the par
(2--4) Check that each file in the par is as expected (using
Archive::Par::file_known)

=cut

$par->check;

my @files = $par->files;
ok @files, 3, 'Files in par (1)';

# Scalar prototype on first argument of ok screws over files_index
ok $par->file_known('test1'), 1, 'Files in par (2)';
ok $par->file_known('test2'), 1, 'Files in par (3)';
ok $par->file_known('test3'), 1, 'Files in par (4)';

# -------------------------------------

=head2 Test 10: File OK

Tests that the Archive::Par instance reports ok to be true.

=cut

ok $par->ok;

# -------------------------------------

=head2 Test 11: File Checked

Tests that the Archive::Par instance reports checked to be true.

=cut

ok $par->checked;

# -------------------------------------
