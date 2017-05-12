#!/pro/bin/perl

use strict;
use warnings;

use Data::Peek;

my %hash = (
    foo => "bar\x{0a}baz",
    bar => [ 1, "mars", \@ARGV ],
    );

print DPeek for DDual ($!, 1);

print "DDumper (\\%hash)\n";
print DDumper \%hash;

print "\$str = DDump (%hash)\n";
my $str = DDump \%hash;
print $str;
print "\%hsh = DDump (%hash)\n";
my %hsh = DDump \%hash;
print DDumper \%hsh;

print "DDump \\%hash\n";
DDump \%hash;

print "\$str = DDump (%hash, 5)\n";
my $str = DDump (\%hash, 1);
print $str;
print "\%hsh = DDump (%hash, 5)\n";
my %hsh = DDump (\%hash, 1);
print DDumper \%hsh;

print "DDump \\%hash, 5\n";
DDump (\%hash, 1);
