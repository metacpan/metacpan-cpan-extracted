# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for cvs2cl

This package tests the basic functionality of cvs2cl.
The tests are cribbed from the redbean set, updated as necessary

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
  plan tests  => 31,
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

=head2 Tests 2--4: Plain Output

This tests the most basic cvs2cl operation, it also tests the implementation
of the fix for bug 27.

The invocation is run as

  cvs2cl --utc --stdin --stdout < 1.log > 1.txt

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '1.log';
  my $output = '1.txt';
  simple_run_test
    ( runargs => [[CVS2CL, '--utc', '--stdin', '--stdout'],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'Plain Output',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 5--7: XML Output

This tests the most basic cvs2cl operation, in XML mode

The invocation is run as

  cvs2cl --utc --stdin --stdout --xml < 1.log > 1.xml

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '1.log';
  my $output = '1.xml';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc --stdin --stdout --xml )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'XML Output',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 8--10: Olivier Vit's XML bug

'

The invocation is run as

  cvs2cl --utc --stdin --stdout -r -b --xml -l -d">2000-03-22;today<" \
    < 2.log > 2-r-b-l-d.xml

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '2.log';
  my $output = '2-r-b-l-d.xml';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc --stdin --stdout -r -b --xml -l 
                               -d">2000-03-22;today<" )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => "Olivier Vit's XML bug",
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 11--13: Shlomo Reinstein's logs (1)

'

He had some filename/directory bugs, and also has some pretty massive
tagnames.

The invocation is run as

  cvs2cl --utc --stdin --stdout < 3.log > 3.txt

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '3.log';
  my $output = '3.txt';
  use Text::Wrap;
  if ( $Text::Wrap::VERSION >= 2001.0130 ) {
    simple_run_test
      ( runargs => [[CVS2CL, qw( --utc --stdin --stdout )],
                    '<', catfile(DATA_DIR, $log_file),
                    '>', $output, '2>', \$err],
        name    => "Shlomo Reinstein's logs (1)",
        errref  => \$err,
        checkfiles => [ $output ],
      );
  } else {
    skip(1, 0) # Skip Text::Wrap too old\n"
      for 11..13;
  }
}

# -------------------------------------

=head2 Test 14--16: Shlomo Reinstein's logs (2)

'

He had some filename/directory bugs, and also has some pretty massive
tagnames.

The invocation is run as

  cvs2cl --utc -r -b -t --stdin --stdout < 3.log > 3-r-b-t.xml

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '3.log';
  my $output = '3-r-b-t.txt';
  use Text::Wrap;
  if ( $Text::Wrap::VERSION >= 2001.0130 ) {
    simple_run_test
      ( runargs => [[CVS2CL, qw( --utc -r -b -t --stdin --stdout )],
                    '<', catfile(DATA_DIR, $log_file),
                    '>', $output, '2>', \$err],
        name    => "Shlomo Reinstein's logs (2)",
        errref  => \$err,
        checkfiles => [ $output ],
      );
  } else {
    skip(1, 0) # Skip Text::Wrap too old\n"
      for 14..16;
  }
}

# -------------------------------------

=head2 Test 17--19: fsf (1)

The invocation is run as

  cvs2cl --utc --fsf -S --stdin --stdout < 4.log > 4-fsf-S.txt

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '4.log';
  my $output = '4-fsf-S.txt';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc --fsf -S --stdin --stdout )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'fsf (1)',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 20--22: fsf (2)

The invocation is run as

  cvs2cl --utc --fsf -S -r --stdin --stdout < 4.log > 4-fsf-S.txt

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '4.log';
  my $output = '4-fsf-S-r.txt';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc --fsf -S -r --stdin --stdout )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'fsf (2)',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 23--25: fsf (3)

The invocation is run as

  cvs2cl --utc --fsf -r --stdin --stdout < 5.log > 5-fsf-r.txt

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '4.log';
  my $output = '4-fsf-r.xml';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc --fsf --xml -r --stdin --stdout )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'fsf (3)',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 26--28: fsf (4)

The invocation is run as

  cvs2cl --utc --fsf -r --stdin --stdout < 5.log > 5-fsf-r.txt

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '5.log';
  my $output = '5-fsf-r.txt';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc --fsf -r --stdin --stdout )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'fsf (4)',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# -------------------------------------

=head2 Test 29--31: fsf (5)

The invocation is run as

  cvs2cl --utc -S --fsf -r --stdin --stdout < 5.log > 5-S-fsf-r.xml

(1) Check that the program ran without error
(2) Check that the output is as expected
(3) Check that no additional files were produced

=cut

{
  my $err = '';
  my $log_file = '5.log';
  my $output = '5-S-fsf-r.txt';
  simple_run_test
    ( runargs => [[CVS2CL, qw( --utc -S --fsf -r --stdin --stdout )],
                  '<', catfile(DATA_DIR, $log_file),
                  '>', $output, '2>', \$err],
      name    => 'fsf (5)',
      errref  => \$err,
      checkfiles => [ $output ],
    );
}

# ----------------------------------------------------------------------------
