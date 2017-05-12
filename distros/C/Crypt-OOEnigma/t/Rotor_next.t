#!/usr/bin/perl -w -I . -I /home/sjb/cvsTrees/local_cvs/hacking/enigma

use Test::More tests => 480;
use Crypt::OOEnigma::Rotor;

my @alpha = (A..Z); # for later use

my $rotor = Crypt::OOEnigma::Rotor->new();

#
#  Tests of next()
#
# The default substitution is the identity and the frequency is 1 so if we keep
# encoding "A" we should see "A" then a progression backwards through the alphabet
my $count = 0;
is($rotor->encode("A"), "A");
$rotor->next();
++$count;
is($rotor->use_count(), $count);
foreach my $res (reverse @alpha){
  my $e = $rotor->encode("A"); 
  is($e, $res),
  is($rotor->revencode($e), "A");
  $rotor->next();
  ++$count;
  is($rotor->use_count(), $count);
}

# Same for a freq of 5
$rotor->freq(5);
$rotor->init();

$count = 0;
for(my $i = 0 ; $i < 5 ; ++$i ){
  is($rotor->encode("A"), "A");
  $rotor->next();
  ++$count;
  is($rotor->use_count(), $count);
}
foreach my $res (reverse @alpha){
  for(my $i = 0 ; $i < 5 ; ++$i ){
    my $e = $rotor->encode("A"); 
    is($e, $res),
    is($rotor->revencode($e), "A");
    $rotor->next();
    ++$count;
    is($rotor->use_count(), $count);
  }
}

exit;

