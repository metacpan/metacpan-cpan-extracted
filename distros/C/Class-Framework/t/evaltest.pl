#!/usr/bin/env perl
use warnings;
use strict;

use FindBin qw( $Bin );
use lib "$Bin";
BEGIN {
	-d "$Bin/../blib/lib" and unshift @INC,"$Bin/../blib/lib";
}
eval q{use PTest2; 1} or die $@;

PTest2->new(a=>1,b=>2,cde=>3,x=>4)->meth2(5);
