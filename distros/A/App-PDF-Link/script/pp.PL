#!/usr/bin/perl

# This script transforms the target source (.pl) into a target script.

my $src = shift;
open( my $fd, ">", $src)
  or die("$src: $!\n");
open( my $fi, "<", "$src.pl" )
  or die("$src.pl: $!\n");

while ( <$fi> ) {

    # The FindBin stuff is only used when running in-place.
    s/^/# /, next if /^use.*FindBin/;

    # App::Packager is only used when running packaged.
    s/^/# /, next if /^use App::Packager/;

}
continue {
    print $fd $_;
}
close($fd);
