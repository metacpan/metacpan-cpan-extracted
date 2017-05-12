# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for cvs2cl

This package tests the --ignore-tag option of cvs2cl

=cut

use File::Spec  qw( );
use FindBin     qw( $Bin );
use Test        qw( ok plan skip );

BEGIN { unshift @INC, $Bin };

sub catfile { File::Spec->catfile(@_) }

use constant CVS2CL     => $ENV{CVS2CL} || ':cvs2cl';
use constant SUBDIR     => 'ignore-tag';

use test                  qw( DATA_DIR );
use test2                 qw( -no-ipc-run simple_run_test );

BEGIN {
  #  1 for compilation test
  #  1 for runcheck
  #  1 for outputfile
  plan tests  => 10,
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

This tests cvs2cl on a log without the --ignore-tag option, to establish a
baseline (and ensure vanilla operation is unaffected).

The invocation is run as

  cvs2cl -r -b -t --stdin --stdout < cvs.log > 3-r-b-t.txt

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

use Text::Wrap;
if ( $Text::Wrap::VERSION >= 2001.0130 ) {
  my $err = '';
  my $log_file   = 'cvs.log';
  my $check_file = '3-r-b-t.txt';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( -r -b -t --stdin --stdout )],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err],
      name           => 'vanilla',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
} else {
  skip('skip: Text::Wrap too old', 0) # Skip Text::Wrap too old\n"
    for 2..4;
}

# -------------------------------------

=head2 Tests 5--7: ignoretag

This tests cvs2cl on a vanilla log with the --ignore-tag option.

The invocation is run as

  cvs2cl -r -b -t --stdin --stdout                                           \
    --ignore-tag                                                             \
    PROD_SampleProd_Date_20_07_2000_Time_10_47_37_IST-2IDT_product_promotion \
    < cvs.log > 3-r-b-t-ignore.txt

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

use Text::Wrap;
if ( $Text::Wrap::VERSION >= 2001.0130 ) {
  my $err = '';
  my $log_file   = 'cvs.log';
  my $check_file = '3-r-b-t-ignore.txt';
  my $tag1 = 
    'PROD_SampleProd_Date_20_07_2000_Time_10_47_37_IST-2IDT_product_promotion';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( -r -b -t --stdin --stdout ),
                          '--ignore-tag' => $tag1],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err ],
      name           => 'ignoretag',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
} else {
  skip('skip: Text::Wrap too old', 0)
    for 5..7;
}

# -------------------------------------

=head2 Tests 8--10: ignoretags

This tests cvs2cl on a vanilla log with the --ignore-tag option.

The invocation is run as

  cvs2cl -r -b -t --stdin --stdout                                           \
    --ignore-tag My_Manual_Tag_20_43_00_27_07_2000                           \
    --ignore-tag                                                             \
    PROD_SampleProd_Date_20_07_2000_Time_10_47_37_IST-2IDT_product_promotion \
    < cvs.log > 3-r-b-t-ignores.txt

( 1) The invocation ran without error (exit status 0).
( 2) This tests that the output of cvs2cl matches what is expected
( 3) This tests that only the expected output files are present.

=cut

{
  my $err = '';
  my $log_file   = 'cvs.log';
  my $check_file = '3-r-b-t-ignore2.txt';
  my $tag1 = 
    'PROD_SampleProd_Date_20_07_2000_Time_10_47_37_IST-2IDT_product_promotion';
  my $tag2 = 'My_Manual_Tag_20_43_00_27_07_2000';

  simple_run_test
    ( runargs        => [[CVS2CL, qw( -r -b -t --stdin --stdout ),
                          '--ignore-tag' => $tag2, '--ignore-tag' => $tag1],
                         '<', catfile(DATA_DIR, SUBDIR, $log_file),
                         '>', $check_file, '2>', \$err ],
      name           => 'ignoretags',
      errref         => \$err,
      testref_subdir => SUBDIR,
      checkfiles     => [ $check_file ],
    );
}

# ----------------------------------------------------------------------------
