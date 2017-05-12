use Test::Base;

plan tests => 1 * blocks;

use FindBin;
use File::Spec;

use Data::AMF;

my $amf = Data::AMF->new( version => 0 );

sub load {
    my $file = File::Spec->catfile( $FindBin::Bin, $_[0] );
    open my $fh, "<$file";
    my $data = do { local $/; <$fh> };
    close $fh;

    $data;
}

sub parse {
    my ($obj) = $amf->deserialize($_[0]);

    return { data => $obj };
}

filters {
    input    => [qw/load parse/],
    expected => 'yaml',
};

run_compare;

__DATA__

=== number
--- input: data/amf0/number
--- expected
data: 123

=== boolean true
--- input: data/amf0/boolean_true
--- expected
data: 1

=== boolean false
--- input: data/amf0/boolean_false
--- expected
data: 0

=== string
--- input: data/amf0/string
--- expected
data: foo

=== object
--- input: data/amf0/object
--- expected
data:
  foo: bar

=== object2
--- input: data/amf0/object2
--- expected
data:
  array:
    - foo
    - bar
  hash:
    foo: bar

=== null object
--- input: data/amf0/null_object
--- expected
data: {}

=== null
--- input: data/amf0/null
--- expected
data: ~

=== undefined
--- input: data/amf0/undefined
--- expected
data: ~

=== reference
--- input: data/amf0/reference
--- expected
data:
  obj1:
    foo: bar
  obj2:
    foo: bar

=== nested reference
--- input: data/amf0/reference_nested
--- expected
data:
  obj:
    foo: bar
  obj2:
    foo: bar
  ary:
    - a
    - b
    - c
  nested:
    ary:
      - a
      - b
      - c
    obj:
      foo: bar

=== ecma array
--- input: data/amf0/ecma_array
--- expected
data:
  0: foo
  bar: baz

=== strict-array
--- input: data/amf0/strict_array
--- expected
data:
  - foo
  - bar
  - baz

=== date
--- input: data/amf0/date
--- expected
data: 1216717318745

=== long string
--- SKIP

