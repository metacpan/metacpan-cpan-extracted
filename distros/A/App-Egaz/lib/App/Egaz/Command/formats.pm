package App::Egaz::Command::formats;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

use constant abstract => 'formats of files use in this project';

sub opt_spec {
    return ( [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        { show_defaults => 1, } );
}

sub usage_desc {
    return "egaz formats";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";

    return $desc;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $desc .= <<MARKDOWN;
* [lav format](http://www.bx.psu.edu/miller_lab/dist/lav_format.html)

    Here <start> and <stop> are origin 1 (i.e. the first base in the original
    given sequence is called '1') and inclusive (both endpoints are included
    in the interval).

* [psl format](https://genome.ucsc.edu/FAQ/FAQformat.html#format2)

    Be aware that the coordinates for a negative strand in a PSL line are
    handled in a special way. In the qStart and qEnd fields, the coordinates
    indicate the position where the query matches from the point of view of
    the forward strand, even when the match is on the reverse strand.
    However, in the qStarts list, the coordinates are reversed.

    Each psl lines contain 21 fields:

        matches misMatches repMatches nCount
        qNumInsert qBaseInsert tNumInsert tBaseInsert
        strand
        qName qSize qStart qEnd
        tName tSize tStart tEnd
        blockCount blockSizes qStarts tStarts

* [axt format](https://genome.ucsc.edu/goldenPath/help/axt.html)

    If the strand value is '-', the values of the aligning organism's start
    and end fields are relative to the reverse-complemented coordinates of
    its chromosome.

* [chain format](https://genome.ucsc.edu/goldenPath/help/chain.html)

* [net format](https://genome.ucsc.edu/goldenPath/help/net.html)

MARKDOWN

    print {$out_fh} $desc;

    return;
}

1;
