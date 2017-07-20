#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Convert::Moji;
my %crazyhash = ("a" => "apple", "b" => "banana");
my $conv = Convert::Moji->new (["table", \%crazyhash]);
my $out = $conv->convert ("a b c");
my $back = $conv->invert ($out);
print "$out, $back\n";
