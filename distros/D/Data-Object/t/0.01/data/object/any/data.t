use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Any';
can_ok 'Data::Object::Any', 'data';

subtest 'test the data method' => sub {
  my $universal = Data::Object::Any->new(undef);
  is $universal->data, undef;
};

ok 1 and done_testing;
