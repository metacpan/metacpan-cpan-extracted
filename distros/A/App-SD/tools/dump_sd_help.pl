#!/usr/bin/perl 
# Process sd help output to put on the website (markdown)
use strict;
use warnings;

open GETHELP, 'sd help |' ;
my @cmds;

# grab what helps exist from the help index
while (<GETHELP>) {
    next if !m/sd help /;
    (undef, undef, my $cmd, undef, my $desc) = split ' ', $_, 5;
    # push @cmds, [$cmd, $desc];
    push @cmds, $cmd;
}

close GETHELP;

# @cmds = ('environment'); # debug

print qq{[[!meta title="Using SD"]]\n};

for (@cmds) {
    open my $cmd, "sd help $_ |";
    my $text = slurp($cmd);

    # now we can do the real processing
    print process_help($text);
}

sub process_help {
    my ( $text ) = shift;

    # escape markdown metacharacters
    $text =~ s/_/\\_/g;

    # linkify http links, adapted from MRE 74
    $text =~ s{
        \b
        # Capture the URL to $1
        (
            # hostname
            http:// (?!example) [-a-z0-9]+(\.[-a-z0-9]+)*\.(com|org|us) \b
            (
                / [-a-z0-9_:\@&?=?=+,.!/~*`%\$]* # optional path
            )?
        )
    }{[$1]($1)}gix;

    # strip off extraneous leading newlines and convert the header into a
    # headline
    $text =~ s/^\n+sd \d\.\d\d - (.*)\n-+\n+/\n$1\n==========\n\n/;

    # strip off any lines that read 'see 'sd help $cmd'' which isn't
    # really appropriate for this as all the helpfiles are being displayed
    # in one place
    #$text =~ s/^.*(?=(?:For more informatio on [\w ]+)? see 'sd help).*$//mgs;

    # put codeblock markers around code blocks
    $text =~ s/((?:^    \S.*\n)+)/> $1/mg;

    # put code annotation markup around code annotations (lines indented
    # by 6 spaces in the raw help (this markup doesn't exist yet in the CSS)
    $text =~ s/((?:^      \S.*\n)+)/<p class="code-annotation">$1<\/p>\n/mg;

    return $text;
}    # process_help_file

sub slurp {
    my $fh = shift;
    local( $/ ) ;
    my $text = <$fh>;

    return $text;
}
