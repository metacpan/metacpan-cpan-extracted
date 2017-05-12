#!/usr/bin/perl
#
# @(#)$Id: setperl.pl,v 2015.1 2015/08/21 22:42:04 jleffler Exp $ 
#
# DBD::Informix for Perl Version 5
#
# Set Perl interpreter
#
# Copyright 2015 Jonathan Leffler
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;

die "Usage: $0 perl source target\n" unless scalar @ARGV == 3;

my $perl = $ARGV[0];
open my $src, "<", $ARGV[1] or die "Failed to open $ARGV[1] for reading";
open my $dst, ">", $ARGV[2] or die "Failed to open $ARGV[2] for writing";

print $dst "#!$perl\n";
my $line = <$src>;  # Skip the first line

while ($line = <$src>)
{
    print $dst $line;
}
