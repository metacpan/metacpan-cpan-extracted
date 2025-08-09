#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok('Business::ES::NIF') || print "Bail out!\n"; }

sub check_obj { return Business::ES::NIF->new(nif => shift); }

subtest 'ISO3166 args' => sub {
  my $o = Business::ES::NIF->new( iso3166 => 1 );
  is($o->iso3166, 1 , 'ISO3166 args');
};

subtest 'ISO3166 Valid' => sub {
  my $es = check_obj('ES01234567L');
  is($es->iso3166, 1 , 'Valid ISO3166');
};

subtest 'ISO3166 Invalid' => sub {
  my $obj = check_obj('PT01234567L');

  is($obj->iso3166 , 0 , 'Error ISO3166');

  $obj->set('ESES01234567L');

  is($obj->iso3166 , 1 , 'Valid ISO3166');
  is($obj->status  , 0 , 'Error is_valid');
  is($obj->error   , 'Error formato de NIF/CIF/NIE', 'Error formato de NIF/CIF/NIE');
};

subtest 'vat()' => sub {
  my $obj = check_obj('01234567L');
  is($obj->vat, 'ES01234567L', 'Format vat() ISO3166 ES');

  $obj->set('ES01234567L');
  is($obj->vat, 'ES01234567L', 'Format set() & vat()');
};

done_testing();
