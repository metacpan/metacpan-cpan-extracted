# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Archive::Par

This package tests the handling of pars with corrupt source files of
Archive::Par.

=cut

use Fatal                    1.02 qw( chmod unlink );
use File::Compare          1.1002 qw( cmp );
use File::Copy               2.03 qw( cp mv );
use File::Spec::Functions         qw( catfile rel2abs );
use FindBin                  1.42 qw( $Bin );
use Test                     1.13 qw( ok plan skip );

use lib $Bin;

use test qw( DATA_DIR REF_DIR
             evcheck );

use constant TESTPAR1 => 'miffy.par';

BEGIN {
  # 1 for compilation test,
  plan tests  => 51,
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
(2--8) The files are each as expected (looking through the return value of 
files)

=cut

$par->check;

my @files = sort $par->files;
ok @files, 5, 'Files in par (1)';

for (1..5) {
  ok $files[$_-1], sprintf("miffy.%d", $_), sprintf("Files in par (%d)", $_+1);
}

# -------------------------------------

=head2 Tests 10--13: Files OK by par

(1) miffy.1 is okay
(2) miffy.3 is not okay
(3) miffy.2 is not okay
(4) miffy.5 is not okay

=cut

ok $par->file_ok('miffy.1');
ok ! $par->file_ok('miffy.3');
ok ! $par->file_ok('miffy.2');
ok ! $par->file_ok('miffy.4');

# -------------------------------------

=head2 Tests 14--16: Files found by par

(1) miffy.1 is found
(2) miffy.3 is found
(3) miffy.2 is found

=cut

ok $par->file_found('miffy.1');
ok $par->file_found('miffy.3');
ok $par->file_found('miffy.2');

# -------------------------------------

=head2 Tests 17--19: Files restorable by par

(1) miffy.1 is not restorable
(2) miffy.2 is not restorable
(3) miffy.3 is restorable

=cut

ok ! $par->file_restorable('miffy.1');
ok ! $par->file_restorable('miffy.2');
ok $par->file_restorable('miffy.3');

# -------------------------------------

=head2 Tests 20--22: Files corrupt by par

(1) miffy.1 is not corrupt
(2) miffy.3 is corrupt

=cut

ok ! $par->file_corrupt('miffy.1');
ok $par->file_corrupt('miffy.3');
ok ! $par->file_corrupt('miffy.2');

# -------------------------------------

=head2 Tests 23--27: Files moved

(1) miffy.1 has not moved
(2) miffy.2 has moved
(3) miffy.3 has not moved
(4) miffy.4 has moved
(5) miffy.5 has not moved

=cut

ok $par->file_moved('miffy.1'), undef, 'Files moved (1)';
ok $par->file_moved('miffy.2'), 'miffy-moved.2', 'Files moved (2)';
ok $par->file_moved('miffy.3'), undef, 'Files moved (3)';
ok $par->file_moved('miffy.4'), 'miffy-moved.4', 'Files moved (4)';
ok $par->file_moved('miffy.5'), undef, 'Files moved (5)';

# -------------------------------------

=head2 Test 28: File not OK

Tests that the Archive::Par instance reports ok to be false.

=cut

ok ! $par->ok;

# -------------------------------------

=head2 Test 29: File Checked

Tests that the Archive::Par instance reports checked to be true.

=cut

ok $par->checked;

# -------------------------------------

=head2 Test 30: File Recoverable

Tests that the Archive::Par instance reports recoverable  to be true.

=cut

ok $par->recoverable;

# -------------------------------------

=head2 Tests 31--33: Files recoverable

Tests that the given files are not individually recoverable, allegedly.

(1) miffy.2
(2) miffy.3
(4) miffy.4

=cut

ok $par->file_recoverable('miffy.2');
ok $par->file_recoverable('miffy.3');
ok $par->file_recoverable('miffy.4');

# -------------------------------------

=head2 Test 34--51: Restore File

Attempts to restore from the par file

(1) Check no exception thrown
(2--6) Check that all files are now ok (as per par instance)
(7--18) For each of miffy.{2,3,4}
  (a) Check that file really exists
  (b) Check that file matches that in testref
  (c) Check that miffy-moved.whatever does not exist
  (d) Check that file.bad does not exist

=cut

my $skip = ! -w DATA_DIR;

unless ( $skip ) {
  for (grep ! $skip, map "miffy.$_", 1,3..5) {
    cp catfile(DATA_DIR, $_), $_
      or die sprintf "Failed to move %s -> %s: $!", catfile(DATA_DIR, $_), $_;
  }
}

skip $skip, evcheck(sub { $par->restore(1) }, 'Restore File (1)'),
   1, 'Restore File (1)';

skip $skip, $par->file_ok(sprintf "miffy.%d", $_)
  for (1..5);

for (2..4) {
  my $recover = catfile DATA_DIR, "miffy.$_";
  my $checkfn = catfile REF_DIR,  "miffy.$_";
  my $old1    = catfile DATA_DIR, "miffy-moved.$_";
  my $old2    = catfile DATA_DIR, "miffy.$_.bad";
  skip $skip, -e $recover;
  skip $skip, cmp($recover, $checkfn), 0, sprintf('Restore File (%d)', $_*3+2);
  skip $skip, ! -e $_
    for $old1, $old2;
}

unless ( $skip ) {
  for (2,4) {
    mv catfile(DATA_DIR, "miffy.$_"), catfile(DATA_DIR, "miffy-moved.$_");
  }
  for (map "miffy.$_", 1,3..5) {
    my $stat = (stat($_))[2] & 0777;
    my $target = catfile(DATA_DIR, $_);
    chmod 0600, $target
      if -e $target; # #4 should be gone
    cp $_, $target
      or die sprintf "Failed to move %s -> %s: $!", $_, $target;
    chmod $stat, $target;
  }
}

# -------------------------------------
