#!/usr/bin/perl -w -I . -I /home/sjb/cvsTrees/local_cvs/hacking/enigma

use Test::More tests => 136 ;
use Storable ;

use Crypt::OOEnigma::Commercial;
use Crypt::OOEnigma::Rotor;

my @alpha = (A..Z); # for later use
my $alpha = (join '', @alpha); # A..Z

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

my @enigmas = ();
my @mesgs = ();
my @results = ();
my @rotors = ();

ROTORS: {
  push @rotors, new Crypt::OOEnigma::Rotor;
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub1);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub2);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub3);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub1, freq => 1);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub2, freq => 26);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub3, freq => 676);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub1, freq => 1, start_position => 10);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub2, freq => 26, start_position => 13);
  push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $sub3, freq => 676, start_position => 22);
}

ENIGMAS: {
  push @enigmas, new Crypt::OOEnigma::Commercial;
  push @enigmas, Crypt::OOEnigma::Commercial->new( rotors => [@rotors[0,1,2]] );
  push @enigmas, Crypt::OOEnigma::Commercial->new( rotors => [@rotors[1,2,3]] );
  push @enigmas, Crypt::OOEnigma::Commercial->new( rotors => [@rotors[4,5,6]] );
  push @enigmas, Crypt::OOEnigma::Commercial->new( rotors => [@rotors[7,8,9]] );
  push @enigmas, Crypt::OOEnigma::Commercial->new( rotors => [@rotors[1,2,3,4,5,6]] );
  push @enigmas, Crypt::OOEnigma::Commercial->new( rotors => [@rotors[4,5,6,7,8,9]] );
  push @enigmas, Crypt::OOEnigma::Commercial->new( rotors => [@rotors[1,2,3,4,5,6,7,8,9]] );
}

MESGS: {
  push @mesgs, "aaaaaaaaaaaaaaaaaaaaaaaaaa"; # 26 A's
  push @mesgs, $alpha ;
  push @mesgs, "The quick brown fox jumped over the lazy dogs"; 

  # A long message, so that the slowest rotor rotates once
}

foreach my $enigma ( @enigmas ){
  ok( defined $enigma, "OOEnigma created" );
  ok( $enigma->isa('Crypt::OOEnigma::Commercial') , "The enigma is the right class");
  foreach my $mesg (@mesgs){
    
    my $preCipher = Storable::dclone($enigma);
    my $cipher = $enigma->encipher($mesg);
    ok($cipher, "There is a resulting cipher");
    push @results, $cipher;
    
    
    my $preDecode = Storable::dclone($enigma);
    my $decode = $enigma->encipher($cipher);
    ok($decode, "There is a resulting decode");
    $mesg =~ s/\s/X/g;
    like($decode, qr/$mesg/i, "Decode");
    is_deeply($preCipher, $preDecode, "The enigma returns to the initial state");
  }
}


#
# Check the results are different
#
my $match_count = 0;
foreach my $r1 (@results) {
  foreach my $r2 (@results) {
    ++$match_count if( $r1 =~ /^$r2$/ )
  }
  ok( $match_count == 1 , "Each result matches only itself");
  $match_count = 0 ;
}

exit;

#
# Test a "real" Commercial enigma with a long message
#
my $enigma = $enigmas[3];

my $long = $alpha ;
for(my $i = 0 ; $i < 676 ; ++$i){
  $long .= $alpha ;
}
  
diag("Enciphering a long message");
my $cipher = $enigma->encipher($long);
ok($cipher, "There is a resulting long cipher");

diag("Deciphering a long message");
my $decode = $enigma->encipher($cipher);
ok($decode, "There is a resulting long decode");

$long =~ s/\s/X/g;
like($decode, qr/$long/i, "Decode of a long message");
  
exit;
