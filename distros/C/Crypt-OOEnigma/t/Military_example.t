#!/usr/bin/perl -w -I . -I /home/sjb/cvsTrees/local_cvs/hacking/enigma

use Test::More tests => 2;

use Crypt::OOEnigma::Military;
use Crypt::OOEnigma::Rotor;

#
# Substitution codes for the 3 rotors in this enigma
my $sub1 = {
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
my $sub2 = {
  A => "Q",
  B => "E",
  C => "W",
  D => "T",
  E => "R",
  F => "A",
  G => "D",
  H => "S",
  I => "F",
  J => "G",
  K => "Z",
  L => "X",
  M => "C",
  N => "V",
  O => "B",
  P => "U",
  Q => "Y",
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
my $sub3 = {
  A => "M",
  B => "W",
  C => "E",
  D => "R",
  E => "T",
  F => "A",
  G => "S",
  H => "D",
  I => "F",
  J => "B",
  K => "Z",
  L => "X",
  M => "C",
  N => "V",
  O => "G",
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
  Z => "Q"
};
#
# The 3 rotors 
#
my @rotors = ();
push @rotors, Crypt::OOEnigma::Rotor->new( cipher => $sub1, 
                                  start_position => 5, 
                                  freq => 1);
push @rotors, Crypt::OOEnigma::Rotor->new( cipher => $sub2, 
                                  start_position => 13, 
                                  freq => 26);
push @rotors, Crypt::OOEnigma::Rotor->new( cipher => $sub3, 
                                  start_position => 22, 
                                  freq => 676);

#
# Our 3-rotor enigma
#
my $enigma = Crypt::OOEnigma::Military->new( rotors => [@rotors[0,1,2]] );

#
# Put to use:
#
$mesg = "The quick brown fox jumped over the lazy dogs"; 
$cipher = $enigma->encipher($mesg);
$decode = $enigma->encipher($cipher);

$mesg =~ s/\s/X/g; # The enigma turns space into "X" before encoding
like($decode, qr/$mesg/i, "Encode-decode successful");

# The OOEnigma can be reused with the same configuration
$mesg = "This is another message to be encoded STOP This works"; 
$cipher = $enigma->encipher($mesg);
$decode = $enigma->encipher($cipher);

$mesg =~ s/\s/X/g; # The enigma turns space into "X" before encoding
like($decode, qr/$mesg/i, "Encode-decode successful");

exit ;
