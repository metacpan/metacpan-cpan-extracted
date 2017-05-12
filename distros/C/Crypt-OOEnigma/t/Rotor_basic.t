#!/usr/bin/perl -w -I . -I /home/sjb/cvsTrees/local_cvs/hacking/enigma

use Test::More tests => 110 ;

use Crypt::OOEnigma::Rotor;

my @alpha = (A..Z); # for later use

#
# A default rotor with an identity substitution
#
my $rotor = Crypt::OOEnigma::Rotor->new();
ok( defined $rotor, "Rotor created" );
ok( $rotor->isa('Crypt::OOEnigma::Rotor') , "The Rotor is the right class");
is( keys(%{$rotor->cipher()}), 26 , "26 letters to encode");
is_deeply($rotor->cipher(), $rotor->current_cipher());

#
# Encode and revencode all letters of the alphabet and see that they are the same
#
foreach my $src (@alpha){
  ok( $src eq $rotor->encode($src), "The default (identity) encode for $src" );
  ok( $src eq $rotor->revencode($src), "The default (identity) revencode for $src" );
  ok( $rotor->encode($src) eq $rotor->revencode($src), "The default (identity) encode-revencode for $src" );
}
ok($rotor->use_count() == 52, "We have encoded the alphabet twice");

#
# Test init method ( also used in new)
#
$rotor->init();
TODO: {
  local $TODO = "Better testing of the initialisation of the ciphers";
}
ok($rotor->use_count() == 0, "Should have reset the use count with init()");
foreach my $src (@alpha){
  ok( $rotor->encode($src) eq $rotor->revencode($src), "As a test of init()" );
}

exit ;
