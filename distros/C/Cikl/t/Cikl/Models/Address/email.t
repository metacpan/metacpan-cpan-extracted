package TestsFor::Cikl::Models::Address::email;
use lib 'testlib';
use base qw(Cikl::Models::Address::TestClass);
use strict;
use warnings;
use Test::More;
use Test::Exception;

use Cikl::Models::Address::email;

sub testing_class { 'Cikl::Models::Address::email'; }

sub test_known_good_emails : Test(2) { 
  my $self = shift;

  ok($self->generate('foo@bar.com'),  'accept foo@bar.com');
  ok($self->generate('foo.bar@bar.com'),  'accept foo.bar@bar.com');
}

sub test_invalid_characters : Test(12) { 
  my $self = shift;
  my @invalid_chars = (
    '(', ')', '<', '>', '@', 
    ',', ';', ':', '\\', '"', 
    '[', ']' );
  foreach my $char (@invalid_chars) {
    dies_ok { $self->generate('asdf' . $char . 'qwer@bar.com') } 'reject ' . $char . ' char';
  }
}
sub test_whitespace : Test(4) { 
  my $self = shift;
  dies_ok { $self->generate('') } 'reject empty string';
  dies_ok { $self->generate('bad address@foo.com') } 'reject string with whitespace';
  dies_ok { $self->generate('   address@foo.com') } 'reject leading whitespace';
  dies_ok { $self->generate('address@foo.com   ') } 'reject trailing whitespace';
}
#
sub test_new_normalized : Test(3) {
  my $self = shift;
  is($self->generate_normalized('ASDF@FOO.COM')->value(), 
      'asdf@foo.com', 'downcase fqdn');

  is($self->generate_normalized('   asdf@bar.com')->value(), 
      'asdf@bar.com', 'remove leading spaces');

  is($self->generate_normalized('asdf@bar.com   ')->value(), 
      'asdf@bar.com', 'remove trailing spaces');

}

Test::Class->runtests;


