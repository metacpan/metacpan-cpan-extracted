use Test::Base;

plan tests => 1 * blocks;

use Data::AMF;

my $amf = Data::AMF->new( version => 0 );

sub serialize {
    $amf->serialize($_[0]->{data});
}

sub deserialize {
    my ($data) = $amf->deserialize($_[0]);
    return { data => $data };
}

filters {
    input => [qw/yaml serialize deserialize/],
    expected => 'yaml',
};

run_compare input => 'input';

__DATA__

=== number
--- input
data: 123

=== boolean true
--- SKIP: currently not supported to format boolean
--- input
data: 1

=== boolean false
--- SKIP: currently not supported to format boolean
--- input
data: 0

=== string
--- input
data: foo

=== object
--- input
data:
  foo: bar

=== null object
--- input
data: {}

=== object2
--- input
data:
  array:
    - foo
    - bar
  hash:
    foo: bar

=== null
--- input
data: ~

=== undefined
--- input
data: ~

=== reference
--- SKIP

=== ecma array
--- input
data:
  0: foo
  bar: baz

=== strict-array
--- input
data:
  - foo
  - bar
  - baz

=== date
--- input
data: 1216717318745

=== long string
--- SKIP

