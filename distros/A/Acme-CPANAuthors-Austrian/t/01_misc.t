#!/usr/bin/env perl
use warnings;
use strict;
use Acme::CPANAuthors;
use Test::More tests => 2;
use Test::Differences;
my $authors = Acme::CPANAuthors->new('Austrian');
is($authors->count, 19, 'number of authors');
eq_or_diff [ sort $authors->id ], [
    qw(
      ANDK AREIBENS DOMM DRRHO FLORIAN GARGAMEL GORTAN KALEX LAMMEL LANTI
      MARCEL MAROS NINE NUFFIN OPITZ PEPL RGIERSIG RURBAN ZEYA
      )
  ],
  'author IDs';
