use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'split';

use Scalar::Util 'refaddr';

subtest 'test the split method' => sub {
  my $split;
  my $string = Data::Object::String->new('name, age, dob, email');

  $split = $string->split(qr/\,\s*/);
  is_deeply $split, ['name', 'age', 'dob', 'email'];
  isa_ok $string, 'Data::Object::String';
  isa_ok $split,  'Data::Object::Array';

  $split = $string->split(qr/\,\s*/, 2);
  is_deeply $split, ['name', 'age, dob, email'];
  isa_ok $string, 'Data::Object::String';
  isa_ok $split,  'Data::Object::Array';

  $split = $string->split(', ');
  is_deeply $split, ['name', 'age', 'dob', 'email'];
  isa_ok $string, 'Data::Object::String';
  isa_ok $split,  'Data::Object::Array';

  $split = $string->split(', ', 2);
  is_deeply $split, ['name', 'age, dob, email'];
  isa_ok $string, 'Data::Object::String';
  isa_ok $split,  'Data::Object::Array';

  $split = $string->split('');
  is_deeply $split,
    [
    'n', 'a', 'm', 'e', ',', ' ', 'a', 'g', 'e', ',', ' ', 'd',
    'o', 'b', ',', ' ', 'e', 'm', 'a', 'i', 'l'
    ];
  isa_ok $string, 'Data::Object::String';
  isa_ok $split,  'Data::Object::Array';
};

ok 1 and done_testing;
