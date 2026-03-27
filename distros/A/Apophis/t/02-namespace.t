use strict;
use warnings;
use Test::More tests => 5;
use Apophis;

# Namespace accessor
my $ca1 = Apophis->new(namespace => 'app-one');
my $ns1 = $ca1->namespace();
like($ns1, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'namespace is a valid UUID v5');

# Same namespace string -> same namespace UUID
my $ca1b = Apophis->new(namespace => 'app-one');
is($ca1b->namespace(), $ns1, 'same namespace string produces same namespace UUID');

# Different namespace string -> different namespace UUID
my $ca2 = Apophis->new(namespace => 'app-two');
isnt($ca2->namespace(), $ns1, 'different namespace string produces different UUID');

# Namespace isolation: same content, different namespaces -> different IDs
my $content = 'identical content';
my $id1 = $ca1->identify(\$content);
my $id2 = $ca2->identify(\$content);
isnt($id1, $id2, 'same content in different namespaces produces different IDs');

# Both still valid v5
like($id2, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-/,
     'ID from second namespace is also valid v5');
