use v5.10;
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Data::ULID::XS', 'ulid'); }
use Data::ULID qw();

isnt \&ulid, \&Data::ULID::ulid, 'not the same ulid function ok';

my $generated = ulid;

is length $generated, 26, 'length ok';

note $generated;

my $perl_generated = Data::ULID::ulid;
my $perl_regenerated = Data::ULID::ulid($generated);

# time part is 10 characters, but it represents microtime, so lets just test first 8
is substr($generated, 0, 8), substr($perl_generated, 0, 8), 'time part ok';
is $generated, $perl_regenerated, 'perl regenerated ok';

my $regenerated = ulid($perl_generated);

is $perl_generated, $regenerated, 'xs regenerated ok';

done_testing;

