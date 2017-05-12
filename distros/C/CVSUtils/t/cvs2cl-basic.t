# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for cvs2cl

This package tests the basic functionality of cvs2cl

=cut

use File::Spec  qw( );
use FindBin     qw( $Bin );
use Test        qw( ok plan );

BEGIN { unshift @INC, $Bin };

sub catfile { File::Spec->catfile(@_) }

use constant CVS2CL     => $ENV{CVS2CL} || ':cvs2cl';
use constant LOG_FILE   => 'Audio-WAV.log';
use constant CHECK_FILE => 'Audio-WAV-ChangeLog.vanilla';

use test                  qw( DATA_DIR );
use test2                 qw( -no-ipc-run simple_run_test );

BEGIN {
  #  1 for compilation test
  #  1 for runcheck
  #  1 for outputfile
  plan tests  => 4,
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

=head2 Test 2: runcheck

This tests that the invocation of cvs2cl ran without error (exit status
0).

The invocation is run as

  cvs2cl --stdin --stdout < data/Audio-WAV.log \
    > Audio-WAV-ChangeLog.vanilla

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
                  '<', catfile(DATA_DIR, LOG_FILE),
                  '>', CHECK_FILE, '2>', \$err],
      name    => 'cvs2cl',
      errref  => \$err,
      checkfiles => [ CHECK_FILE ],
    );
}

# ----------------------------------------------------------------------------
