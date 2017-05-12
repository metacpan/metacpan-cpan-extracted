#!/usr/bin/perl -w -I . -I /home/sjb/cvsTrees/local_cvs/hacking/enigma

use Test::More tests => 736 ;

use Crypt::OOEnigma::Rotor;

my @alpha = (A..Z); # for later use

#
# use a more interesting substitution in the same rotor
#
my $newSub = {
  A => "Q",
  B => "W",
  C => "E",
  D => "R",
  E => "T",
  F => "A",
  G => "S",
  H => "D",
  I => "F",
  J => "G",
  K => "Z",
  L => "X",
  M => "C",
  N => "V",
  O => "B",
  P => "Y",
  Q => "U",
  R => "I",
  S => "O",
  T => "P",
  U => "H",
  V => "J",
  W => "K",
  X => "L",
  Y => "N",
  Z => "M"
};
my $rotor = Crypt::OOEnigma::Rotor->new(cipher => $newSub);
ok($rotor->use_count() == 0, "Reset the use count with init()");
is_deeply($rotor->cipher(), $rotor->current_cipher());

#
# Some sample encodings
#
is($rotor->encode("A"), "Q");
is($rotor->encode("D"), "R");
is($rotor->encode("G"), "S");
is($rotor->encode("O"), "B");
is($rotor->encode("X"), "L");

# Test rotate of the new subst
for(my $p = 0 ; $p <= 26 ; ++$p){
  $rotor->rotate($p);
  foreach my $src (@alpha){
    ok( $src eq $rotor->revencode($rotor->encode($src)), "Decode-encode tests" );
  }
  $rotor->init();
  ok($rotor->use_count() == 0, "Reset the use count with init()");
}

