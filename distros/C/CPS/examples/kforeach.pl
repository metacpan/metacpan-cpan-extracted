#!/usr/bin/perl

use strict;
use warnings;

use CPS qw( gkforeach kpar );
use CPS::Governor::Deferred;

my $gov = CPS::Governor::Deferred->new;

gkforeach( $gov, [ 1 .. 10 ],
   sub { 
      my ( $item, $knext ) = @_;

      print "A$item ";
      goto &$knext;
   },
   sub {},
);

gkforeach( $gov, [ 1 .. 10 ],
   sub {
      my ( $item, $knext ) = @_;

      print "B$item ";
      goto &$knext;
   },
   sub {},
);

$gov->flush;

print "\n";
