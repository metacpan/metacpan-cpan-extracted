# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 21;
use Path::Class qw{file};

BEGIN { use_ok( 'DBIx::Array::Connect' ); }


my $ini = file(file($0)->dir => "db-config.ini");
my $dac = DBIx::Array::Connect->new(file=>$ini);
isa_ok($dac, 'DBIx::Array::Connect');

{
  my $hash = $dac->section_hash("section-hash");
  isa_ok($hash, "HASH");
  is($hash->{"type"}, "section-hash");
  is($hash->{"active"}, "0");
  isa_ok($hash->{"list"}, "ARRAY");
  is(scalar(@{$hash->{"list"}}), 3);
  is($hash->{"list"}->[0], "a");
  is($hash->{"list"}->[1], "b");
  is($hash->{"list"}->[2], "c");
  is($hash->{"scalar"}, "1");
  is($hash->{"empty"}, "");
}

{
  my %hash = $dac->section_hash("section-hash");
  is($hash{"type"}, "section-hash");
  is($hash{"active"}, "0");
  isa_ok($hash{"list"}, "ARRAY");
  is(scalar(@{$hash{"list"}}), 3);
  is($hash{"list"}->[0], "a");
  is($hash{"list"}->[1], "b");
  is($hash{"list"}->[2], "c");
  is($hash{"scalar"}, "1");
  is($hash{"empty"}, "");
}
