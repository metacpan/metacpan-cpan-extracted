package TestsFor::Cikl::DataTypes::Asn;
use lib 'testlib';
use base qw(Cikl::DataTypes::TestClass);
use strict;
use warnings;
use Test::More;

use Cikl::DataTypes::Asn;

sub testing_class { "Cikl::DataTypes::Asn"; }

sub test_validation : Test(7) {
  my $self = shift;
  my $type = $self->get_constraint();
  ok(! $type->check(-1), "-1 is not a valid ASN");
  ok($type->check(0), "0 is a valid ASN");
  ok($type->check(1), "1 is a valid ASN");
  ok($type->check(65535), "65535 is a valid ASN");
  ok($type->check((2**32) - 1), "2^32 - 1 is a valid ASN");
  ok(! $type->check(2**32), "2^32 is not a valid ASN");
}

Test::Class->runtests;
