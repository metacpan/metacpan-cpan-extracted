# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for cvs2cl

This package tests the options functionality of cvs2cl

=cut

use File::Spec            qw( );
use FindBin               qw( $Bin );
use Test                  qw( ok plan );

BEGIN { unshift @INC, $Bin };

sub catfile { File::Spec->catfile(@_) }

use constant LOG_FILE         => 'Audio-WAV.log';
use constant CHECK_FILE_R     => 'Audio-WAV-ChangeLog.-r';
use constant CHECK_FILE_B     => 'Audio-WAV-ChangeLog.-b';
use constant CHECK_FILE_T     => 'Audio-WAV-ChangeLog.-t';
use constant CHECK_FILE_NT    => 'Audio-WAV-ChangeLog.notimes';
use constant CHECK_FILE_NCD   => 'Audio-WAV-ChangeLog.no-common-dir';
use constant CHECK_FILE_FSF   => 'Audio-WAV-ChangeLog.FSF';
use constant CHECK_FILE_DELTA => 'Audio-WAV-ChangeLog.delta';
use constant CVS2CL     => $ENV{CVS2CL} || ':cvs2cl';

use test                  qw( DATA_DIR );
use test2                 qw( -no-ipc-run simple_run_test );

BEGIN {
  #  1 for compilation test
  #  1 for runcheck
  #  1 for outputfile
  plan tests  => 25,
       todo   => [],
       ;
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

# No modules imported

ok 1, 1, 'compilation';

printf STDERR "Using CVS2CL: %s\n", CVS2CL
  if $ENV{TEST_DEBUG};

# -------------------------------------

=head2 Test 2--4: cvs2cl -r

This tests that the invocation of cvs2cl ran without error (exit status
0).

The invocation is run as

  cvs2cl --stdin --stdout -r < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.-r

=head2 Test 3: outputcheck

This tests that the output of cvs2cl matches what is expected

=head2 Test 4: no extra files

This tests that only the expected output files (Audio-WAV-ChangeLog.vanilla)
are present.

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '-r', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE_R, '2>', \$err],
      name    => 'cvs2cl -r',
      errref  => \$err,
      checkfiles => [ CHECK_FILE_R ],
    );
}

# -------------------------------------

=head2 Test 5--7: cvs2cl -b

This tests that the invocation of cvs2cl ran without error (exit status
0).

The invocation is run as

  cvs2cl --stdin --stdout -b < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.-b

=head2 Test 6: outputcheck

This tests that the output of cvs2cl matches what is expected

=head2 Test 7: no extra files

This tests that only the expected output files (Audio-WAV-ChangeLog.vanilla)
are present.

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '-b', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE_B, '2>', \$err],
      name    => 'cvs2cl -b',
      errref  => \$err,
      checkfiles => [ CHECK_FILE_B ],
    );
}

# -------------------------------------

=head2 Test 8--10: cvs2cl -t

This tests that the invocation of cvs2cl ran without error (exit status
0).

The invocation is run as

  cvs2cl --stdin --stdout -t < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.-t

=head2 Test 9: outputcheck

This tests that the output of cvs2cl matches what is expected

=head2 Test 10: no extra files

This tests that only the expected output files (Audio-WAV-ChangeLog.vanilla)
are present.

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '-t', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE_T, '2>', \$err],
      name    => 'cvs2cl -t',
      errref  => \$err,
      checkfiles => [ CHECK_FILE_T ],
    );
}

# -------------------------------------

=head2 Test 11--13: cvs2cl --no-times

This tests the --no-times option of cvs2cl
0).

The invocation is run as

  cvs2cl --no-times --stdin --stdout < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.notimes

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '--no-times', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE_NT, '2>', \$err],
      name    => 'cvs2cl --no-times',
      errref  => \$err,
      checkfiles => [ CHECK_FILE_NT ],
    );
}

# -------------------------------------

=head2 Test 14--16: cvs2cl --no-common-dir

This tests the --no-common-dir option of cvs2cl

The invocation is run as

  cvs2cl --no-common-dir --stdin --stdout < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.no-common-dir

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '--no-common-dir', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE_NCD, '2>', \$err],
      name    => 'cvs2cl --no-common-dir',
      errref  => \$err,
      checkfiles => [ CHECK_FILE_NCD ],
    );
}

# -------------------------------------

=head2 Test 17--19: cvs2cl -W

This tests the -W option of cvs2cl

The invocation is run as

  cvs2cl --stdin --stdout -r -W 1800 < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.no-common-dir

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file   = '1.log';
  my $check_file = '1-W1800.txt';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --stdin --stdout -r ), -W => 1800 ],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $check_file, '2>', \$err],
      name    => 'cvs2cl -W',
      errref  => \$err,
      checkfiles => [ $check_file ],
    );
}

# -------------------------------------

=head2 Test 20--22: cvs2cl --FSF

This tests the --FSF option of cvs2cl

The invocation is run as

  cvs2cl --FSF --stdin --stdout < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.no-common-dir

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '--FSF', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE_FSF, '2>', \$err],
      name    => 'cvs2cl --FSF',
      errref  => \$err,
      checkfiles => [ CHECK_FILE_FSF ],
    );
}

# -------------------------------------

=head2 Test 23--25: cvs2cl --delta

This tests the --delta option of cvs2cl

The invocation is run as

  cvs2cl --delta r1_00:r1_01 -t --stdin --stdout < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.delta

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '--delta' => 'r1_00:r1_01',
                   qw( -t --stdin --stdout)],
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE_DELTA, '2>', \$err],
      name    => 'cvs2cl --delta',
      errref  => \$err,
      checkfiles => [ CHECK_FILE_DELTA ],
    );
}

# ----------------------------------------------------------------------------
