#!/usr/bin/perl -w -I . -I /home/sjb/cvsTrees/local_cvs/hacking/enigma

use Test::More tests => 29 ;
use Crypt::OOEnigma::Reflector;

my @alpha = (A..Z); # for later use

#
# A default reflector
#
my $reflector = Crypt::OOEnigma::Reflector->new();
ok( defined $reflector, "Reflector created" );
ok( $reflector->isa('Crypt::OOEnigma::Reflector') , "The Reflector is the right class");
is( keys(%{$reflector->cipher()}), 26 , "26 letters to encode");

while((my $key, my $value) = each(%{$reflector->cipher()})){
  is($reflector->reflect($key), $value);
}

exit ;
