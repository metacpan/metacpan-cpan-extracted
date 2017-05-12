#!/usr/bin/perl

my $src = shift;
open( my $fd, ">", $src)
  or die("$src: $!\n");
open( my $fi, "<", "$src.pl" )
  or die("$src.pl: $!\n");
while ( <$fi> ) {
    next if /^use lib .*FindBin/;
    print $fd $_;
}
close($fd);
