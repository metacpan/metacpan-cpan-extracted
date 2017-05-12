#!/usr/bin/perl -w -I . -I /home/sjb/cvsTrees/local_cvs/hacking/enigma

use Test::More tests => 729 ;

use Crypt::OOEnigma::Rotor;

my @alpha = (A..Z); # for later use
my $rotor = Crypt::OOEnigma::Rotor->new();

#
# Test rotate
#
for(my $p = 0 ; $p <= 26 ; ++$p){
  $rotor->rotate($p);
  foreach my $src (@alpha){
    ok( $src eq $rotor->revencode($rotor->encode($src)), "Decode-encode tests" );
  }
  $rotor->init();
  ok($rotor->use_count() == 0, "Should have reset the use count with init()");
}

exit;
