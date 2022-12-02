use v5.10;
use strict;
use warnings;

use Test::More;
use Data::ULID::XS qw(binary_ulid);

use Data::ULID qw();

isnt \&binary_ulid, \&Data::ULID::binary_ulid, 'not the same binary_ulid function ok';

my $generated = binary_ulid;

is length $generated, 16, 'length ok';

my $perl_generated = Data::ULID::binary_ulid;
my $perl_regenerated = Data::ULID::binary_ulid($generated);

# time part is 6 bytes, but it represents microtime, so lets just test first 5
is substr($generated, 0, 5), substr($perl_generated, 0, 5), 'time part ok';
is $generated, $perl_regenerated, 'perl regenerated ok';

my $regenerated = binary_ulid($perl_generated);

is $perl_generated, $regenerated, 'xs regenerated ok';

done_testing;

