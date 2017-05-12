#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use C::Utility 'lineout';
use File::Slurper 'read_text';
my $file = "$Bin/some.c";
my $c = <<EOF;
static void unknown (int x) { return x; }
#lineout
int main () { return 0; }
EOF
lineout ($c, $file);
print read_text ($file);
unlink $file or die $!;
