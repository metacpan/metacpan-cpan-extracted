#!perl
use Cwd 'getcwd';
use Test2::V0;
use Test2::Tools::Command;
local @Test2::Tools::Command::command = ( $^X, '--', './bin/ly-fu' );

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

    $ENV{TMPDIR}       = getcwd();
    $ENV{MIDI_EDITOR}  = 'true';
    $ENV{SCORE_VIEWER} = 'true';

    my ( $result, $status, $stdout, $stderr ) = command {
        args   => [qw(--layout c)],
        stdout => qr/ly-fu\.\S+\.ly/
    };
    my $outfile = $$stdout;
    chomp $outfile;
    ok( -f $outfile, "Lilypond generated $outfile" );
    $outfile =~ s/ly$/pdf/;
    ok( -f $outfile, "PDF generated $outfile" );
    $outfile =~ s/pdf$/midi/;
    ok( -f $outfile, "MIDI generated $outfile" );

    unlink glob 'ly-fu.*' unless $ENV{AUTHOR_TEST_JMATES};
}

done_testing
