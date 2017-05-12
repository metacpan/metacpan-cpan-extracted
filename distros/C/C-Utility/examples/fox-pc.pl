#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use C::Utility 'convert_to_c_string_pc';
my $string =<<'EOF';
The quick "brown" fox\@farm
jumped %over the lazy dog.
EOF
print convert_to_c_string_pc ($string);
