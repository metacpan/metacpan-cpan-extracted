package TestsFor::Cikl::Models::Address::ipv4;
use lib 'testlib';
use base qw(Cikl::Models::Address::TestClass);
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Cikl::Models::Address::ipv4;

sub testing_class { "Cikl::Models::Address::ipv4"; }

sub test_known_valid_ipv4 : Test(2) { 
  my $self = shift;

  ok($self->generate("0.0.0.0"),  "accept 0.0.0.0");
  ok($self->generate("255.255.255.255"),  "accept 255.255.255.255");
}

sub test_known_invalid_ipv4 : Test(4) { 
  my $self = shift;
  dies_ok { $self->generate("256.1.1.1") }  "reject 256.1.1.1";
  dies_ok { $self->generate("1.256.1.1") }  "reject 1.256.1.1";
  dies_ok { $self->generate("1.1.256.1") }  "reject 1.1.256.1";
  dies_ok { $self->generate("1.1.1.256") }  "reject 1.1.1.256";
}

sub test_cidrs : Test(1) { 
  my $self = shift;
  dies_ok { $self->generate("10.0.0.0/24") }  "reject cidr";
}

sub test_new_normalized : Test(2) {
  my $self = shift;
  is($self->generate_normalized("   1.2.3.4")->value(), 
      '1.2.3.4', "remove leading spaces");

  is($self->generate_normalized("1.2.3.4   ")->value(), 
      '1.2.3.4', "remove trailing spaces");
}

Test::Class->runtests;

