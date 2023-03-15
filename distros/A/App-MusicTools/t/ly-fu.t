#!perl
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/ly-fu' );

# ly-fu is tricky to test, as how does one automate checking that the
# MIDI generated is correct (difficult) or that the lilypond score is
# okay (much harder)? Also, it requires that lilypond be available...

my $lilypond_path;
for my $d ( split ':', $ENV{PATH} ) {
    my $loc = File::Spec->catfile( $d, 'lilypond' );
    if ( -x $loc ) {
        $lilypond_path = $loc;
        last;
    }
}

SKIP: {
    skip "lilypond not installed", 2 unless defined $lilypond_path;

    diag
      "NOTE ly-fu will fail if lilypond is ancient (but only if lilypond installed)";

    my ( $result, $status, $stdout, $stderr ) =
      command { args => [qw(--layout --silent c)], stdout => qr/ly-fu\.\S+\.ly/ };
    my $outfile = $$stdout;
    chomp $outfile;
    ok( -f $outfile, 'temp file generated' );
}

done_testing
