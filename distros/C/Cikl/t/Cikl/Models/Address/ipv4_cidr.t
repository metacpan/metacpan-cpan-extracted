package TestsFor::Cikl::Models::Address::ipv4_cidr;
use lib 'testlib';
use base qw(Cikl::Models::Address::TestClass);
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Cikl::Models::Address::ipv4_cidr;

sub testing_class { "Cikl::Models::Address::ipv4_cidr"; }

sub test_known_valid_ipv4_cidr : Test(2) { 
  my $self = shift;

  ok($self->generate("0.0.0.0/0"),  "accept 0.0.0.0/0");
  ok($self->generate("255.255.255.255/32"),  "accept 255.255.255.255/32");
}

sub test_bad_ip_in_cidr : Test(4) { 
  my $self = shift;
  dies_ok { $self->generate("256.1.1.1/24") }  "reject 256.1.1.1/24";
  dies_ok { $self->generate("1.256.1.1/24") }  "reject 1.256.1.1/24";
  dies_ok { $self->generate("1.1.256.1/24") }  "reject 1.1.256.1/24";
  dies_ok { $self->generate("1.1.1.256/24") }  "reject 1.1.1.256/24";
}

sub test_invalid_cidr_mask : Test(2) { 
  my $self = shift;
  dies_ok { $self->generate("8.8.8.8/33") }  "reject 8.8.8.8/33";
  dies_ok { $self->generate("8.8.8.8/-1") }  "reject 8.8.8.8/-1";
}

sub test_invalid : Test(3) { 
  my $self = shift;
  dies_ok { $self->generate("  8.8.8.8/24") }  "reject leading whitespace";
  dies_ok { $self->generate("8.8.8.8/24   ") }  "reject trailing whitespace";
  dies_ok { $self->generate("8.8.8.8") }  "reject bare ipv4";
}

sub test_new_normalized : Test(2) {
  my $self = shift;
  is($self->generate_normalized("   1.2.3.4/24")->value(), 
      '1.2.3.4/24', "remove leading spaces");

  is($self->generate_normalized("1.2.3.4/24   ")->value(), 
      '1.2.3.4/24', "remove trailing spaces");
}

Test::Class->runtests;


