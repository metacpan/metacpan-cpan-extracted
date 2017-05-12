package Business::EDI::Generator;

# Common functions for the scripts used to generate class modules.

use strict;
use warnings;

our $VERSION = 0.01;

use Exporter::Easy (
    EXPORT => [qw( :all )],
    TAGS => [
        all => [qw( next_line next_chunk quotify safename )],
    ],
);

sub next_line {
    my $line = <STDIN>;
    defined($line) or return;
    $line =~ s/\s*$//;      # kill trailing spaces
    $line .= "\n";          # replacing ^M DOS line endings
    if (@_ and $_[0]) {
        $line = next_line() while ($line !~ /\S/);    # skip empties
    }
    return $line;
}

sub next_chunk {
    my $chunk = '';
    my $piece;
    while ($piece = next_line) { # need to get back a blank line (no '1' for next_line())
        defined($piece) or last;
        $piece =~ /\S/ or last;  # blank means we're done
        $piece =~ s/^\s*//;      # kill leading  spaces
        $piece =~ s/\s*$//;      # kill trailing spaces
        $chunk .= ' ' if $chunk; # add a space, if necessary, to keep words from runningtogether.
        $chunk .= $piece;
    }
    return $chunk;
}

sub quotify {
    my $string = shift or return '';
    $string =~ /'/ or return     "'$string'"    ;   # easiest case, safe for single quotes
    $string =~ /"/ or return '"' . $string . '"';   # contains single quotes, but no doubles.  use doubles
    $string =~ s/'/\\'/g;                           # otherwise it has both, so we'll escape the singles
    return  "'$string'" ;
}

sub safename {
    my $string = shift; 
    $string =~ s/[^A-z0-9]//;   # no weird charaters (e.g. punctuation) in filenames
    return $string;
}

1;

