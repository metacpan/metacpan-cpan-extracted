#!perl

# ly-fu is tricky to test, as how does one automate checking that the
# MIDI generated is correct (difficult) or that the lilypond score is
# okay (much harder)? Also, it requires that lilypond be available.
#
# XXX add author test, below, as time permits.

use File::Spec ();
use Test::Cmd;
use Test::Most tests => 2;

my $lilypond_path;
for my $d ( split ':', $ENV{PATH} ) {
  my $loc = File::Spec->catfile( $d, 'lilypond' );
  if ( -x $loc ) {
    $lilypond_path = $loc;
    last;
  }
}

# XXX really need to parse `lilypond --version` to ensure using > 2.14
# or whatever minimum is set in ly-fu; however, that output is screwy,
# being neither to stdout nor stderr, so would need to wrap lilypond
# with some IPC foo capable of capturing such shenanigans. Sigh. So will
# get false positives from smoke test machines with older versions of
# lilypond installed. (on the "will" front, I don't think this has
# happened (yet), as CPAN smoke test boxes seem to not install old
# versions of lilypond to PATH for various reasons)

SKIP: {
  skip "lilypond not installed", 2 unless defined $lilypond_path;

  diag
    "NOTE ly-fu will fail if lilypond is ancient (but only if lilypond installed)";

  my $test_prog = './ly-fu';
  my $tc        = Test::Cmd->new(
    interpreter => $^X,
    prog        => $test_prog,
    verbose     => 0,            # TODO is there a standard ENV to toggling?
    workdir     => '',
  );
  $tc->run( args => '--layout --silent c' );
  my $outfile = $tc->stdout;
  chomp $outfile;
  ok( -f $outfile, 'check that temp file generated' );
  is( $tc->stderr, "", "ly-fu call emits no stderr" );
}

# XXX listen, verify something with ear and eye
# TODO except I never remember to run author tests so uh yeah about that
#if ( $ENV{AUTHOR_TEST_JMATES} ) {
#SKIP: {
#    skip "lilypond not installed", 42 unless defined $lilypond_path;
#  }
#}
