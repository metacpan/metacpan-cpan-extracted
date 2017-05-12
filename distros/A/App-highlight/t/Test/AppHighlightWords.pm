package Test::AppHighlightWords;

#############################################################################
## helper functions for redirecting STDIN in App::highlight tests
#############################################################################

use base 'Exporter';
our @EXPORT = qw(open_words_txt_as_stdin restore_stdin);

use File::Basename;
use File::Spec;

my $real_stdin;

sub open_words_txt_as_stdin {
    my $file = shift;

    if (!defined($file)) {
        $file = 'words.txt';
    }

    my $words_txt = File::Spec->catfile(
        dirname(dirname(__FILE__)),
        $file
    );

    $real_stdin = *STDIN;
    close(STDIN);
    open(*STDIN, '<', $words_txt)
        or die "Unable to open $words_txt for reading";
}

sub restore_stdin {
    close(STDIN);
    *STDIN = $real_stdin;
}

1;
