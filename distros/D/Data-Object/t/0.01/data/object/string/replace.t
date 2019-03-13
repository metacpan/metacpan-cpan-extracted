use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';
can_ok 'Data::Object::String', 'replace';

use Scalar::Util 'refaddr';

subtest 'test the replace method' => sub {
  my $string   = Data::Object::String->new('Hello World');
  my $replaced = $string->replace('World', 'Universe');

  isnt refaddr($string), refaddr($replaced);
  is "$replaced", 'Hello Universe';    # Hello Universe
  isa_ok $string,   'Data::Object::String';
  isa_ok $replaced, 'Data::Object::String';

  $string   = Data::Object::String->new('Hello World');
  $replaced = $string->replace('world', 'Universe', 'i');
  is "$replaced", 'Hello Universe';    # Hello Universe
  isa_ok $string,   'Data::Object::String';
  isa_ok $replaced, 'Data::Object::String';

  $string   = Data::Object::String->new('Hello World');
  $replaced = $string->replace(qr/world/i, 'Universe');
  is "$replaced", 'Hello Universe';    # Hello Universe
  isa_ok $string,   'Data::Object::String';
  isa_ok $replaced, 'Data::Object::String';

  $string   = Data::Object::String->new('Hello World');
  $replaced = $string->replace(qr/.*/, 'Nada');
  is "$replaced", 'Nada';              # Nada
  isa_ok $string,   'Data::Object::String';
  isa_ok $replaced, 'Data::Object::String';
};

ok 1 and done_testing;
