use strict;
use warnings;

use English;

=head1 DESCRIPTION

Find all the characters in the data files.

=cut

# Slurp entire file into memory, then analyze it.
undef $INPUT_RECORD_SEPARATOR;

my %seen_chars;
while ( defined ( my $contents = <> ) ) {
	for my $c ( 0 .. length( $contents ) - 1 ) {
		my $one_char = substr( $contents, $c, 1 );
        $seen_chars{ $one_char } = 1;
    }
}

print "Chars: " . join( ' ', ( sort keys %seen_chars ) ) . "\n";

