# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for cvs2cl

This package tests the --show-tag option of cvs2cl (intoduced in CVSUtils
1.01 / bug #26).

=cut

use File::Spec  qw( );
use FindBin     qw( $Bin );
use Test        qw( ok plan skip );

BEGIN { unshift @INC, $Bin };

sub catfile { File::Spec->catfile(@_) }

use constant CVS2CL     => $ENV{CVS2CL} || ':cvs2cl';
use constant SUBDIR     => 'show-tag';

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

if ( $ENV{TEST_DEBUG} ) {
  printf STDERR "Using CVS2CL: %s\n", CVS2CL;
}

# -------------------------------------

=head2 Tests 2--4: vanilla

This tests cvs2cl on a log without the --show-tag option, to establish a
baseline (and ensure vanilla operation is unaffected).

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout < cvs.log > fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs.log';
  my $check_file = 'fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'vanilla',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# -------------------------------------

=head2 Tests 5--7: vanilla-date

This tests cvs2cl on a log without the --show-tag option, to establish a
baseline (and ensure vanilla operation is unaffected).

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout < cvs-date.log > fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs-date.log';
  my $check_file = 'date.fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'vanilla-date',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# -------------------------------------

=head2 Tests 8--10: vanilla-tag

This tests cvs2cl on a log without the --show-tag option, to establish a
baseline (and ensure vanilla operation is unaffected).

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout < cvs-1-7.log > fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs-1-7.log';
  my $check_file = 'tag.fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'vanilla-tag',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# -------------------------------------

=head2 Tests 11--13: vanilla-tag-date

This tests cvs2cl on a log without the --show-tag option, to establish a
baseline (and ensure vanilla operation is unaffected).

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout < cvs-both.log > fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs-both.log';
  my $check_file = 'both.fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'vanilla-tag-date',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# -------------------------------------

=head2 Tests 14--16: showtag

This tests cvs2cl on a vanilla log with the --show-tag option.

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout --show-tag ILAB-1-7 \
    < cvs.log > showtag.fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs.log';
  my $check_file = 'showtag-tag.fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout
                                      --show-tag ILAB-1-7 )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'showtag',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# -------------------------------------

=head2 Tests 17--19: showtag-date

This tests cvs2cl on a pre-date-pruned log with the --show-tag option.

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout --show-tag ILAB-1-7 \
    < cvs-date.log > showtag-date.fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs-date.log';
  my $check_file = 'showtag-date.fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout
                                      --show-tag ILAB-1-7 )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'showtag-date',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# -------------------------------------

=head2 Tests 20--22: showtag-tag

This tests cvs2cl on a pre-tag-pruned log with the --show-tag option.

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout --show-tag ILAB-1-7 \
    < cvs-1-7.log > showtag-tag.fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs-1-7.log';
  my $check_file = 'showtag-tag.fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout
                                      --show-tag ILAB-1-7 )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'showtag-tag',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# -------------------------------------

=head2 Tests 23--25: showtag-both

This tests cvs2cl on a pre-both-pruned log with the --show-tag option.

The invocation is run as

  cvs2cl --fsf -S -r -t --stdin --stdout --show-tag ILAB-1-7 \
    < cvs-both.log > showtag-both.fsf-S-r-t

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs-both.log';
  my $check_file = 'showtag-both.fsf-S-r-t';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( --fsf -S -r -t --stdin --stdout
                                      --show-tag ILAB-1-7 )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'showtag-both',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# ----------------------------------------------------------------------------
