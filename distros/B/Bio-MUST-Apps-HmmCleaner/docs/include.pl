#!/usr/bin/env perl

use Modern::Perl '2011';
use autodie;


# process first file on command line or STDIN
my $infile = shift @ARGV;
my $in = \*STDIN;
open $in, '<', $infile if $infile;

parse(q{}, $in);


sub parse {
    my ($pad, $fh) = @_;

    LINE:
    while (my $line = <$fh>) {

        if ($line =~ m/\A (\s*) \\include\{ ([^ \} ]+) \} /xms) {

            # extract padding whitespace and include filename
            my ($inc_pad, $include) = ($1, $2);
            open my $inc, '<', $include;

            # recursively handle include (accumulating padding whitespace)
            parse("$pad$inc_pad", $inc);
            next LINE;
        }

        # insert padding whitespace before each line of the included file
        # corresponding to the depth of the \include{} directive
        print "$pad$line";
    }

    return;
}
