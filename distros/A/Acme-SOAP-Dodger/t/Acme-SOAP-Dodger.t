#!/usr/bin/perl -w

use strict;
use warnings;

use File::Temp qw/tempfile tempdir/;
use Test::More tests => 3;

# OK then. You might not have SOAP::Lite installed. So let us generate one
# ourselves.

my $dir = tempdir(CLEANUP => 1);
mkdir "$dir/SOAP";
my ($fh, $t_mod) = tempfile(DIR => "$dir/SOAP", UNLINK => 1);
my @info = <DATA>; chomp @info;
print $fh "$_\n" for @info;
close $fh;
unshift @INC, $dir;
link $t_mod, "$dir/SOAP/Fake.pm";

use_ok 'SOAP::Fake';
use_ok 'Acme::SOAP::Dodger';
eval { SOAP::Fake->shower_gel };
ok $@, $@;

unlink "$dir/SOAP/Fake.pm";

__DATA__
package SOAP::Fake;

sub shower_gel { "You wash my back and I'll wash yours" }

return qw/Imperialistic leather infidel dawgs/;
