#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use C::Utility 'stamp_file';
my $out = '';
stamp_file (\$out);
print $out;
