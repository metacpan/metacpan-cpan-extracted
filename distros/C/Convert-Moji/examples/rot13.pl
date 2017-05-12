#!/home/ben/software/install/bin/perl
use warnings;
use strict;
# Examples of rot13 transformers:
use Convert::Moji;
# Using a table
my %rot13;
@rot13{('a'..'z')} = ('n'..'z','a'..'m');
my $rot13 = Convert::Moji->new (["table", \%rot13]);
# Using tr
my $rot13_1 = Convert::Moji->new (["tr", "a-z", "n-za-m"]);
# Using a callback
sub rot_13_sub { tr/a-z/n-za-m/; return $_ }
my $rot13_2 = Convert::Moji->new (["code", \&rot_13_sub]);
# Then to do the actual conversion
my $out = $rot13->convert ("secret");
# You also can go backwards with
my $inverted = $rot13->invert ("frperg");
print "$out\n$inverted\n";


