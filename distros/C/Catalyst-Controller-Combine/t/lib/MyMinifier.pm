package MyMinifier;
use base 'Exporter';

our @EXPORT = qw(minify);

sub minify {
    my $text = shift;
    
    return "# $text #";
}

1;
