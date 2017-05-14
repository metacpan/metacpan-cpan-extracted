package App::elsquid;
use strict;
use warnings;
use feature ':5.10';

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(parse_line);



sub parse_line {  #  See: https://adblockplus.org/en/filters
    $_ = $_[0];

    my $domchars        = qr/[-a-zA-Z0-9.]+/;

    
    my $result = {};  # {} or { d => ... } or { u => ... } or { e => ... }

    
    return {} if /^\[/;
    return {} if /^!/;

    return {} if /^\@\@/;
    return {} if /#\@#/;

    return {} if /##/;

    return {} if /\$.*domain=/;

    
    if (/^\|\|($domchars)\^(\$|$)/) {
        my $domain = $1;
        # Output domain here for debugging purposes.
        return { d => $domain };
    }
    
    return {} if /\$/;

    
    return {} if m,^\|http://,;
    

    if (/^\|\|/) {
        s/^\|\|//;
        s/\^$//;

        
        # URL (no ^ * |) ?
        if (/^$domchars\// && !/\^/ && !/\*/ && !/\|/ ) {
            return { u => $_ }
        }
    }

    
    # Must be expression now; eventually with ^ * |  in it:

    my $caret    = "CCCCCC";
    my $asterisk = "AAAAAA";
    my $pipe     = "PPPPPPP";

    s/\^/$caret/g;
    s/\*/$asterisk/g;
    s/\|/$pipe/g;

    $_ = quotemeta;

    s/$caret/[\/?]/;
    s/$asterisk/.*/g;
    s/$pipe$/\$/;
    s/$pipe//;

    return { e => $_ };
}



1;


__END__

=head1 NAME

App::elsquid - Helper module for the elsquid command


=head1 DESCRIPTION

Nothing in here is meant for public consumption.  Use L<elsquid>
from the command line.


=head1 AUTHOR

Axel Miesen <miesen@quadraginta-duo.de>
