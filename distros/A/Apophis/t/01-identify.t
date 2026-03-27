use strict;
use warnings;
use Test::More tests => 8;
use Apophis;

my $ca = Apophis->new(namespace => 'test-identify');
ok($ca, 'constructor returns object');
isa_ok($ca, 'Apophis');

# Determinism: same content -> same UUID
my $content = 'hello world';
my $id1 = $ca->identify(\$content);
my $id2 = $ca->identify(\$content);
is($id1, $id2, 'same content produces same UUID');

# Format: valid UUID v5
like($id1, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'UUID is v5 format');

# Different content -> different UUID
my $other = 'goodbye world';
my $id3 = $ca->identify(\$other);
isnt($id1, $id3, 'different content produces different UUID');

# Empty content
my $empty = '';
my $id4 = $ca->identify(\$empty);
like($id4, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-/,
     'empty content produces valid v5 UUID');
isnt($id4, $id1, 'empty content differs from non-empty');

# Binary content with nulls
my $binary = "foo\x00bar\x00baz";
my $id5 = $ca->identify(\$binary);
like($id5, qr/^[0-9a-f]{8}-/, 'binary content with nulls works');
