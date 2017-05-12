use FindBin;
use lib "$FindBin::Bin/lib";

use Acme::Buga 'buga';

## OO api
my $b = Acme::Buga->new;

my $en = $b->encode('Test');
print "Encode: $en \n";

my $de = $b->decode($en);
print "Decode: $de \n";

## using alternative constructor
my $en_static = buga('Test Static')->encode;
print "Encode Static: $en_static\n";

my $de_static = buga($en_static)->decode;
print "Decode Static: $de_static\n";
