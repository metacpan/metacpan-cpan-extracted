#!perl

# $Id: gen_dummy_kdb_pm.plx,v 1.1 2002/09/03 02:00:31 steiner Exp $

# Get basic info from KDB.in for dummy version of KDB.pm in d/ directory
# This file is needed so CPAN can find version and documentation for KDB.pm

use vars qw($VERSION $Usage);

$VERSION = do{my@r=q$Revision: 1.1 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

$Usage = "Usage: $0\n";

my $InFile = "KDB.in";
my $OutFile = "d/KDB.pm";

open(IN, $InFile) or die "Can't open $InFile: $!\n";
open(OUT, ">$OutFile") or die "Can't open $OutFile: $!\n";

print OUT "### This is a dummy file so CPAN will find the file and VERSION\n";
print OUT "### This file is generated from '$InFile' by '$0'\n\n";

while (<IN>) {  # find and print package statement and $VERSION
    if (/^package /) {
	print OUT $_;
    }
    if (/^\$VERSION/) {
	print OUT $_;
	last;
    }
}

print OUT "\n# This is to make sure require will return an error\n";
print OUT "0;\n";

while (<IN>) {  # find and print docs
    if (/^__END__/) {
	print OUT $_;
	last;
    }
}
while(<IN>) {  # print documentation
    print OUT $_;
}

close OUT;
close IN;
