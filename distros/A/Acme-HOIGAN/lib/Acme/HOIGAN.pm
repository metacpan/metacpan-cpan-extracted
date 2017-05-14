package Acme::HOIGAN;
# ABSTRACT: convert text into HOIGAN!

use strict;
use warnings;


sub HOIGAN {
   my ($text) = @_;

   # convert to uppercase
   $text = uc($text);

   # algunos saludan
   if (rand > 0.95) {
      my $saludo = ('OIGAN! ', 'OYGA! ', 'HOIGAN! ', 'HOYGAN! ' )[int(rand(4))];
      $text = "$saludo$text";
   }

   # Eliminamos acentos
   $text =~ tr/ÁÉÍÓÚÀÈÌÒÙáéíóúàèìòùñ/AEIOUAEIOUAEIOUAEIOUÑ/;

   # Causuistica chunga de haber, a ver, aver..
   $text =~ s/A VER/rand > 0.75 ?'HABER':'A VER'/ge;
   $text =~ s/HABER/rand > 0.75 ?'A VER':'AVER'/ge;

   $text =~ s/(\w+)/hoigan_word($1)/ge;

   # Punto con espacio detras, anadimos puntos o ponemos exclamaciones
   $text =~ s/(\.\s+)/rand > 0.25 ? '.' x int(rand(7)+1) . ' ':'!' x int(rand(7)+1) . ' '/ge;
   # Eliminamos puntuacion, y la que queda pasa a ser solo punto.
   $text =~ s/(\.+|\,|\;)/rand > 0.50 ? ' ':'.'/ge;

   return $text;
}

our $vowels = {
  'A' => 1,
  'E' => 1,
  'I' => 1,
  'O' => 1,
  'U' => 1
};

sub hoigan_word {
  my ($word) = @_;

  # sustituir aleatoriamente A por HA y HA por A
  return 'HA' if ($word eq 'A' and rand > 0.80);
  return 'A' if ($word eq 'HA' and rand > 0.90);

  # intercalar haches donde no hace falta
  $word =~ s/([AEIOU])([AEIOU])/(rand > 0.90)?"$1H$2":"$1$2"/ge;
  $word =~ s/([E])([AEIOU])/(rand > 0.90)?"$1H$2":"$1$2"/ge;

  $word =~ s/CION$/SION/ if (rand > 0.05);

  # Quitar haches intercaladas...
  $word =~ s/(\w)H/(rand > 0.30)?"$1":"$1H"/ge;

  # haches a principio de palabra empezada en vocal
  my $first_letter = substr($word, 0, 1);
  if ($vowels->{$first_letter} and length($word) > 1 and rand > 0.60) {
     $word = "H$word";
  }

  $word =~ s/Ñ/(rand > 0.05)?'NI':(rand > 0.20)?'NY':'Ñ'/;

  $word =~ s/QU/(rand > 0.10)?'K':'QU'/ge;
  $word =~ s/C(A|O|U)/(rand > 0.10)?"K$1":"C$1"/ge;
  #cl suena a K
  $word =~ s/CL/K/g if (rand > 0.90);

  # Letra ese, repetida, si es a final de palabra, con más probabilidad
  $word =~ s/([A-RT-Z])S/rand > 0.95 ? "$1S":$1 . ("S" x int(rand(2)+1))/ge;
  $word =~ s/S$/rand > 0.25 ? 'S':'S' x int(rand(3)+1)/ge;

  # Y pasa a LL
  $word =~ s/Y(\w)/rand > 0.50 ? "LL$1":"Y$1"/ge;

  $word =~ s/(B|V)/('B','V')[int(rand(2))]/ge;

  return $word;
}

1;

#################### main pod documentation begin ###################

=head1 NAME
Acme::HOIGAN - Convert text into HOIGAN!!!

=head1 SYNOPSIS

  use Acme::HOIGAN;
  my $text = Acme::HOIGAN::HOIGAN('Un poco de texto')

=head1 DESCRIPTION

Convert text to authentic internet HOIGAN dialect.

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

Copyright (c) 2015 by Jose Luis Martinez Torres
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.
the full text of the license can be found in the
LICENSE file included with this module.

=cut

