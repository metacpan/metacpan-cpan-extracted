#!/usr/bin/perl
use lib '../lib';
use CGI::Inspect;

print "Content-type: text/html\n\n";

my $food = "toast";

for my $i (1..10) {
  print "$i cookies for me to eat...<br>";
  inspect() if $i == 5; # be sure to edit $toast :)
}
print "I also like $food!";
