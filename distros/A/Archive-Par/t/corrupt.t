# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Archive::Par

This package tests the handling of pars with too many broken source files of
Archive::Par, and a corrupt par file.

=cut

use Fatal                 1.02 qw( close open );
use File::Basename         2.6 qw( basename );
use File::Spec::Functions      qw( catfile rel2abs);
use FindBin               1.42 qw( $Bin );
use Test                  1.13 qw( ok plan );

use lib $Bin;

use test qw( DATA_DIR
             evcheck );

use constant TESTPAR1 => 'Angel_3x12_-_Provider_SVCD_<Read_NFO>_*Par_Files*_03_of_10_-_Angel.3x12.SVCD.C00Ki3.TheTube.par';

use constant FOUND_FILES =>
  ('Angel 3x12 - Provider SVCD <Read NFO> 03 of 58 ' .
     '- Angel.3x12.SVCD.C00Ki3.TheTube.rar',
   map (sprintf('Angel 3x12 - Provider SVCD <Read NFO> %02d of 58 ' .
                '- Angel.3x12.SVCD.C00Ki3.TheTube.r%02d', $_+4, $_),
        0..10,13,16,28,33,38,40,49,51..54));

BEGIN {
  # 1 for compilation test,
  plan tests  => 93,
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

=head2 Test 4: check

Check the file, using the secret squirrel check hook to read the contents of
the file, rather than invoke C<par c>.

Check no exception thrown.

=cut

{
  open my $fh, '<', $fn;
  ok evcheck(sub{
               (my $realfn = basename($fn)) =~ tr!_! !;
               $par->check($realfn, $fh);
             }, 1, 'Check');
  close $fh;
}

# -------------------------------------

=head2 Tests 5--61: Files in par

Check that each file in the par is as expected

(1) There are 56 files found
(2--57) The files are each as expected (looking through the return value of
files)

=cut

my @files = sort $par->files;
ok @files, 56, 'Files in par (1)';

for my $i (0..54) {
  my $fn = sprintf "Angel.3x12.SVCD.C00Ki3.TheTube.r%02d", $i;
  ok $files[$i], $fn, sprintf("Files in par (%d)", 2+$i);
}
ok $files[55], 'Angel.3x12.SVCD.C00Ki3.TheTube.rar', 'Files in par (57)';

# -------------------------------------

=head2 Tests 62--63: Files Found by par

(1) Check that r33 is found, as per $par
(2) Check that r48 is not found, as per $par

=cut

ok $par->file_found('Angel.3x12.SVCD.C00Ki3.TheTube.r33');
ok ! $par->file_found('Angel.3x12.SVCD.C00Ki3.TheTube.r48');

# -------------------------------------

=head2 Tests 64--65: Files OK by par

(1) Check that r54 is not ok, as per $par
(2) Check that r50 is not ok, as per $par

=cut

ok ! $par->file_ok('Angel.3x12.SVCD.C00Ki3.TheTube.r54');
ok ! $par->file_ok('Angel.3x12.SVCD.C00Ki3.TheTube.r50');

# -------------------------------------

=head2 Tests 66--68: Files Restorable by par

(1) Check that r11 is not restorable, as per $par
(2) Check that r27 is not restorable, as per $par
(3) Check that r48 is not restorable, as per $par

=cut

ok ! $par->file_restorable('Angel.3x12.SVCD.C00Ki3.TheTube.r11');
ok ! $par->file_restorable('Angel.3x12.SVCD.C00Ki3.TheTube.r27');
ok ! $par->file_restorable('Angel.3x12.SVCD.C00Ki3.TheTube.r48');

# -------------------------------------

=head2 Test 69: File Not Recoverable

Tests that the Archive::Par instance reports recoverable to be false.

=cut

ok ! $par->recoverable;

# -------------------------------------

=head2 Tests 70--93: fs_files

Tests that the fs_files found are as expected.

(1--23) Each file found was expected
(24)    23 files were found.

=cut

my %found_files = map { catfile(DATA_DIR,$_) => 1 } FOUND_FILES;
my @fs_files = $par->fs_files;

ok exists $found_files{$_} for @fs_files;
ok @fs_files, keys %found_files;

__END__


Angel 3x12 - Provider SVCD <Read NFO> 04 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r00
Angel 3x12 - Provider SVCD <Read NFO> 05 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r01
Angel 3x12 - Provider SVCD <Read NFO> 06 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r02
Angel 3x12 - Provider SVCD <Read NFO> 07 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r03
Angel 3x12 - Provider SVCD <Read NFO> 08 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r04
Angel 3x12 - Provider SVCD <Read NFO> 09 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r05
Angel 3x12 - Provider SVCD <Read NFO> 10 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r06
Angel 3x12 - Provider SVCD <Read NFO> 11 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r07
Angel 3x12 - Provider SVCD <Read NFO> 12 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r08
Angel 3x12 - Provider SVCD <Read NFO> 13 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r09
Angel 3x12 - Provider SVCD <Read NFO> 14 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r10
Angel 3x12 - Provider SVCD <Read NFO> 17 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r13
Angel 3x12 - Provider SVCD <Read NFO> 20 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r16
Angel 3x12 - Provider SVCD <Read NFO> 32 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r28
Angel 3x12 - Provider SVCD <Read NFO> 37 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r33
Angel 3x12 - Provider SVCD <Read NFO> 42 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r38
Angel 3x12 - Provider SVCD <Read NFO> 44 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r40
Angel 3x12 - Provider SVCD <Read NFO> 53 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r49
Angel 3x12 - Provider SVCD <Read NFO> 55 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r51
Angel 3x12 - Provider SVCD <Read NFO> 56 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r52
Angel 3x12 - Provider SVCD <Read NFO> 57 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r53
Angel 3x12 - Provider SVCD <Read NFO> 58 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.r54
Angel 3x12 - Provider SVCD <Read NFO> 03 of 58 - Angel.3x12.SVCD.C00Ki3.TheTube.rar
