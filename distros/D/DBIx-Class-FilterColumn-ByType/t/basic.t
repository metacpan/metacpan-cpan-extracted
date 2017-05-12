use strict;
use warnings;

use Test::More;
use Test::Deep;

use lib 't/lib';

use A::Schema;

my $s = A::Schema->connect('dbi:SQLite::memory:');
$s->deploy;

my $artist = $s->resultset('Artist')->create({ first_name => 'foo', last_name => 'bar' });
$artist->update({ counter => 5 });
$artist->discard_changes;

is $artist->first_name, 'foo12', 'filter_from_storage and filter_to_storage run for array input';
is $artist->last_name, 'bar12', 'filter_from_storage and filter_to_storage run for array input';
is $artist->counter, 15, 'counter set properly on scalar input';

is $A::Schema::Result::Artist::from_storage_ran, 2, 'filter_from_storage counter incremented';
is $A::Schema::Result::Artist::to_storage_ran, 3, 'filter_to_storage counter incremented';

my $zeta = $s->resultset('Zeta')->create({ counter => 5 });
$zeta->discard_changes;

is $zeta->counter, 500, 'baseclass real filter run, not artist real filter';

done_testing;
