#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use C::Tokenize '$include';
my $c = <<EOF;
#include <this.h>
#include "that.h"
EOF
while ($c =~ /$include/g) {
    print "Include statement $1 includes file $2.\n";
}
