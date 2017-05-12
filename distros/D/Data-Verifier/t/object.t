use strict;
use Test::More;
use Test::Exception;

use Data::Verifier;

{
  package DV::Test::Class1;
  use Moose;
  has name => (
            is => 'rw',
            isa => 'Str',
           );
}

{
 my $verifier = Data::Verifier->new(
     profile => {
         name    => {
             required => 1
         }
     }
 );

 my $test_obj = DV::Test::Class1->new(name => 'foo');

 my $results = $verifier->verify($test_obj);

 ok($results->success, 'success');
 cmp_ok($results->valid_count, '==', 1, '1 valid');
 cmp_ok($results->invalid_count, '==', 0, 'none invalid');
 cmp_ok($results->missing_count, '==', 0, 'none missing');
 ok($results->is_valid('name'), 'name is valid');
 cmp_ok($results->get_value('name'), 'eq', 'foo', 'get_value');
 cmp_ok($results->get_original_value('name'), 'eq', 'foo', 'get_original_value');
}

{
  package DV::Test::Class2;
  use Moose;
  has bar => (
            is => 'rw',
            isa => 'Str',
           );
}

{
 my $verifier = Data::Verifier->new(
     profile => {
         name    => {
             required => 1,
         }
         }
 );

 my $test_obj = DV::Test::Class2->new(bar => 'foo');
 my $results = $verifier->verify($test_obj);

 ok(!$results->success, 'failure');
 cmp_ok($results->valid_count, '==', 0, '0 valid');
 cmp_ok($results->invalid_count, '==', 0, '0 invalid');
 cmp_ok($results->missing_count, '==', 1, '1 missing');
 ok(!$results->is_valid('name'), 'name is not valid');
 ok(!$results->is_invalid('name'), 'name is invalid');
 ok($results->is_missing('name'), 'name is missing');
 ok(!defined($results->get_value('name')), 'name has no value');
}

{
  package DV::Test::Class3;
  use Moose;
  has name => (
            is => 'rw',
            isa => 'Str',
           );
  has age => (
           is => 'rw',
           isa => 'Int',
          );
}

{
 my $verifier = Data::Verifier->new(
     profile => {
         name    => {
             required => 1
         },
         age     => {
             required => 1,
             type => 'Int'
         }
     }
 );

 my $test_obj = DV::Test::Class3->new(name => 'foo', age => 0);
 my $results = $verifier->verify($test_obj);

 ok($results->success, 'success');
 cmp_ok($results->valid_count, '==', 2, '2 valid');
 cmp_ok($results->invalid_count, '==', 0, 'none invalid');
 cmp_ok($results->missing_count, '==', 0, 'none missing');
 ok($results->is_valid('name'), 'name is valid');
 cmp_ok($results->get_value('name'), 'eq', 'foo', 'get_value');
 ok($results->is_valid('age'), 'age is valid');
 my %valids = $results->valid_values;
 is_deeply(\%valids, { name => 'foo', age => 0 }, 'valid_values');
}

done_testing;