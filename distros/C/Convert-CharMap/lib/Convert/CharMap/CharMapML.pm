package Convert::CharMap::CharMapML;
use 5.006;
use strict;
use warnings;
use XML::Simple;

our $VERSION = '0.10';

sub in {
    my $class = shift;
    return XMLin( +shift, keeproot => 1 );
}

sub out {
    my $class = shift;
    return XMLout(
        +shift,
        keeproot => 1,
        xmldecl  => '<?xml version="1.0" encoding="UTF-8" ?>' . "\n"
          . '<!DOCTYPE characterMapping SYSTEM "http://www.unicode.org/unicode/reports/tr22/CharacterMapping.dtd">'
    );
}

1;
