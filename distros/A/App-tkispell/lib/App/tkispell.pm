package App::tkispell;

use strict;
use warnings;

our $VERSION = "0.20";

1;

__END__

=encoding utf-8

=head1 NAME

App::tkispell - Perl/Tk user interface for ispell.

=head1 SYNPOSIS

tkispell [<filename>]

=head1 DESCRIPTION

C<tkispell> is a Perl/Tk graphical user interface to GNU ispell (or the successor aspell).

Tkispell opens the file given as a command line argument.  
The "Select File...," button also allows users to select a file.

The, "Check...," button begins the spell check process.  The listing
at the top of the window shows unrecognized words, and the listing in
the middle of the window shows the alternative spellings provided by
ispell.

Clicking the, "Dismiss," button exits the program, after asking if the
program should save the spell-checked file and the replacement words
in the user's personal dictionary if necessary.

The entry box at the lower right contains replacement text for
misspelled words.  The text in the entry is either a selection
from the word guesses or a word entered by the user.

Buttons on the right side of the window select options for replacing
possibly misspelled words.

=head2 Accept

Accept the word and continue to the next unrecognized word.

=head2 Add

Add the unrecognized word to the personal dictionary.

=head2 Replace

Replace the misspelled word.

=head2 Replace All

Replace all occurrences of the misspelled word.


=head1 PERSONAL DICTIONARY

Tkispell uses ispell's personal dictionary naming conventions:
$HOME/.ispell_<language> or $HOME/.ispell_default if the $LANG
environment variable is, "C," or is not set.

=head1 COPYRIGHT

Copyright © 2001-2020 Robert Kiesling, rkies@cpan.org.
Copyright © 2020 Robert Kiesling, rkies@cpan.org and Alexander Becker.

Alexander Becker has served as a co-maintainer since version 0.17.

Licensed under the same terms as Perl. Refer to the file, "Artistic."

=head1 SEE ALSO

perl(1), ispell(1), aspell(1), L<Tk>

=cut




