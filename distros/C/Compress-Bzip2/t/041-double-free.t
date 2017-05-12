# -*- mode: perl -*-

use Test::More tests => 1;

use strict;
BEGIN {
  use_ok('Compress::Bzip2');
};

do './t/lib.pl';

# [cpan #28366] double free or corruption on 32 bit, threaded
my $INFILE = catfile( qw(bzlib-src sample1.ref) );
my $bz = bzopen($INFILE, 'rb') ;
print "a";
while ($bz->bzreadline($_) > 0) {}
$bz->bzclose ();
