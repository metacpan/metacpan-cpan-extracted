# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for cvs2cl

This package tests the known bugs functionality of cvs2cl (have gone away)

=cut

use File::Spec  qw( );
use FindBin     qw( $Bin );
use Test        qw( ok plan skip );

BEGIN { unshift @INC, $Bin };

sub catfile { File::Spec->catfile(@_) }

use constant CVS2CL     => $ENV{CVS2CL} || ':cvs2cl';

use test                  qw( DATA_DIR );
use test2                 qw( -no-ipc-run simple_run_test );

BEGIN {
  #  1 for compilation test
  #  1 for runcheck
  #  1 for outputfile
  plan tests  => 19,
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

if ( $ENV{TEST_DEBUG} ) {
  printf STDERR "Using CVS2CL: %s\n", CVS2CL;
}

# -------------------------------------

=head2 Tests 2--4: longnames

This tests cvs2cl handling long file names.

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

The invocation run is

  cvs2cl --stdin --stdout < data/longname.log > longname.txt

=cut

{
  use Text::Wrap;
  if ( $Text::Wrap::VERSION >= 2001.0130 ) {
    my $err = '';
    my $log_file  = 'longname.log';
    (my $check_file = $log_file) =~ s/\.log$/.txt/;
    simple_run_test
      ( runargs => [[CVS2CL, '--stdin', '--stdout'],
                    '<', catfile(DATA_DIR, $log_file),
                    '>', $check_file, '2>', \$err],
        name    => 'cvs2cl',
        errref  => \$err,
        checkfiles => [ $check_file ],
      );
  } else {
    skip(1, 0) # Skip Text::Wrap too old\n"
      for 2..4;
  }
}

# -------------------------------------

=head2 Test 5--7: bug 7

This tests that an identified bug in cvs2cl in handling directories called '0'
(actually in handling multiple files in directories called '0'), wherein
cvs2cl loops forever, is no longer present.

The invocation is run as

  cvs2cl --stdin --stdout < data/6.log > 6.vanilla

=head2 Test 3: outputcheck

This tests that the output of cvs2cl matches what is expected

=head2 Test 4: no extra files

This tests that only the expected output files (Audio-WAV-ChangeLog.vanilla)
are present.

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, '6.log'),
                  '>', '6.vanilla', '2>', \$err],
      name    => 'bug 7',
      errref  => \$err,
      checkfiles => [ '6.vanilla' ],
    );
}

# -------------------------------------

=head2 Test 8--10: bug 5

This tests that -W 0 does not fail

The invocation is run as

  cvs2cl --stdin --stdout -W 0 < data/6.log > 6.vanilla

=head2 Test 3: outputcheck

This tests that the output of cvs2cl matches what is expected

=head2 Test 4: no extra files

This tests that only the expected output files (Audio-WAV-ChangeLog.vanilla)
are present.

=cut

{
  my $err = '';
  simple_run_test
    ( runargs => [[CVS2CL, '--stdin', '--stdout', -W => 0 ],
                  '<', catfile(DATA_DIR, '6.log'),
                  '>', '6.vanilla', '2>', \$err],
      name    => 'bug 7',
      errref  => \$err,
      checkfiles => [ '6.vanilla' ],
    );
}

# -------------------------------------

=head2 Test 11-13: bug 17

This tests the most cvs2cl operation, in XML mode, with a specific encoding.

The invocation is run as

  cvs2cl --utc --stdin --stdout --xml --xml-encoding ISO-8859-1 < 1.log \
    > 1.iso-8859-1.xml

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '1.log';
  my $output = '1.iso-8859-1.xml';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc --stdin --stdout --xml
                               --xml-encoding ISO-8859-1 )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'bug 17',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 14-16: bug 22

This tests that spurious extra square brackets (appeared in 1.15) around
single version numbers have gone away.

The invocation is run as

  cvs2cl -r -b --stdin --stdout < squarebrackets.log > squarebrackets.-r-b.CL

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = 'squarebrackets.log';
  my $output = 'squarebrackets.-r-b.CL';
  simple_run_test
    ( runargs => [[CVS2CL, qw( -r -b --stdin --stdout )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'bug 22',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Tests 17--19: bug 27

This tests that the squashing of duplicate filenames doesn't get over-zealous
when dealing with revisions from -r (and thus squash different revisions).

The invocation is run as

  cvs2cl -r --utc --stdin --stdout < 1.log > 1-r.txt

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '1.log';
  my $output = '1-r.txt';
  simple_run_test
    ( runargs => [[CVS2CL, '-r', '--utc', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'bug 27',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}


# ----------------------------------------------------------------------------
