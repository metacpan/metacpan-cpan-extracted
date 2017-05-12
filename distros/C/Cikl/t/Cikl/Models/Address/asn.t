package TestsFor::Cikl::Models::Address::asn;
use lib 'testlib';
use base qw(Cikl::Models::Address::TestClass);
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Cikl::Models::Address::asn;

sub testing_class { 'Cikl::Models::Address::asn'; }

sub test_known_good_asns : Test(4) { 
  my $self = shift;

  ok($self->generate(0),  'accept 0');
  ok($self->generate(1234),  'accept 1234');
  ok($self->generate(65535),  'accept 65535');
  ok($self->generate((2**32) - 1),  'accept 2^32 - 1');
}

sub test_known_invalid_asns : Test(5) { 
  my $self = shift;

  dies_ok { $self->generate(-1) }  'reject -1';
  dies_ok { $self->generate(2**32) }  'reject 2^32';
  dies_ok { $self->generate("asdf") }  'reject asdf';
  dies_ok { $self->generate("   1234") }  'reject leading whitespace';
  dies_ok { $self->generate("1234   ") }  'reject trailing whitespace';
}

sub test_new_normalized : Test(2) {
  my $self = shift;

  is($self->generate_normalized('   1234')->value(), 
      1234, 'remove leading spaces');

  is($self->generate_normalized('1234   ')->value(), 
      1234, 'remove trailing spaces');

}

Test::Class->runtests;



