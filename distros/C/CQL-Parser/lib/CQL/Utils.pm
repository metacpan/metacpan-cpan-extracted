package CQL::Utils;

use strict;
use warnings;
use base qw( Exporter );
our @EXPORT_OK = qw( indent xq renderPrefixes );

## not for public consumption

sub indent {
    my $level = shift || 0;
    return "    " x $level; 
}

sub xq {
    my $string = shift || '';
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    return $string;
}

sub renderPrefixes {
    my ($level, @prefixes) = @_;
    return '' if @prefixes == 0;
    my $buffer = indent($level)."<prefixes>\n";
    for my $prefix (@prefixes) {
        $buffer .= indent($level+1)."<prefix>\n";
        $buffer .= indent($level+2)."<name>".$prefix->getName()."</name>\n"
            if $prefix->getName();
        $buffer .= indent($level+2)."<identifier>".$prefix->getIdentifier().
            "</identifier>\n";
        $buffer .= indent($level+1)."</prefix>\n";
    }
    $buffer .= indent($level)."</prefixes>\n";
}

1;
