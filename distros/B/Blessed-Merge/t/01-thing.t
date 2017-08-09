use Test::More;

use strict;
use warnings;

use JSONP;

my $one = JSONP->new();
my $two = JSONP->new();

$one->thing = { a => 'b', array => [{ a => 'c' }, 3, 'hey'] };
$two->thing = { c => 'd', array => [{ d => 'f' }, 2] };

use Blessed::Merge;

my $blessed = Blessed::Merge->new({});

my $new = $blessed->merge($one, $two);

is($new->thing->a, 'b');
is($new->thing->c, 'd');
is_deeply($new->thing->array, [{ a => 'c', d => 'f' }, 2, 'hey']);

done_testing;

