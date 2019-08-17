#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Date qw/now today date rdate :const idate/;
use Storable qw/freeze nfreeze thaw dclone/;
say "START";

my $d = now();
my $clone = dclone($d);
my $copy = date($clone);
say $copy;
