use strict;
use warnings;

sub render {
    my $unused_in_heredoc_file;
    my $name = 'world';
    my $text = <<"END";
Hello, $name!
A heredoc body PPI would drop when stringifying the document.
END
    return $text;
}

render();
