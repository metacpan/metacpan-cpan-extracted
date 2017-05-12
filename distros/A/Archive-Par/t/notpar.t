# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Archive::Par

This package tests the handling of non par files by Archive::Par

=cut


use File::Spec::Functions      qw( catfile rel2abs);
use FindBin               1.42 qw( $Bin );
use Test                  1.13 qw( ok plan );

use lib $Bin;

use Archive::Par;
use test qw( DATA_DIR
             evcheck );

use constant TESTPAR1 => 'notpar.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 7,
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

Run C<< $par->check >>.  Check exception thrown.

=cut

ok evcheck(sub { $par->check }, 'Run check'), 0, 'Run check';


# -------------------------------------

=head2 Test 6: Files in par

(1) Check there are 0 files in the par

=cut

my @files = $par->files;
ok @files, 0, 'Files in par (1)';

# -------------------------------------

=head2 Test 7: File Checked

Tests that the Archive::Par instance reports checked to be false.

=cut

ok ! $par->checked;

# -------------------------------------
