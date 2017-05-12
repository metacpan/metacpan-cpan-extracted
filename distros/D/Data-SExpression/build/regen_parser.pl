#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Regenerate lib/Data/SExpression/Parser.pm from Parser.yp using
Parse::Yapp

This script is used during the build process instead of depending on
being able to locate `yapp'.

=cut

my $INFILE  = "lib/Data/SExpression/Parser.yp";
my $OUTFILE = "lib/Data/SExpression/Parser.pm";
my $PACKAGE = "Data::SExpression::Parser";

eval "use Parse::Yapp";
if($@) {
    warn "Parse::Yapp uninstalled, unable to regenerate Parse.pm.\n";
    exit 0;
}

my $parser = Parse::Yapp->new(inputfile => $INFILE);

open(my $out, ">", $OUTFILE);

print $out $parser->Output(classname  => $PACKAGE,
                           standalone => 1);

close($out);
