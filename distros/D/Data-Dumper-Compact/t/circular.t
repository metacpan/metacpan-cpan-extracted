use strict;
use warnings;
use Test::More;

use Data::Dumper::Compact;

my $can_j = eval { require JSON::Dumper::Compact; 1 };

my $circular = {
  quux => { bar => 73 },
  foo => { baz => [ 42 ] },
};

$circular->{foo}{baz}[1] = $circular->{foo};

is(
  Data::Dumper::Compact->dump($circular),
  '{ foo => { baz => [ 42, $_->{foo} ] }, quux => { bar => 73 } }'."\n"
);

if ($can_j) {
  is(
    JSON::Dumper::Compact->dump($circular),
    '{
  "foo": { "baz": [
      42, { "$ref": "#/foo" }
      ,
  ] },
  "quux": { "bar": 73 },
}
');
}

done_testing;
