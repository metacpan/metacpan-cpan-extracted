use Test::More;

use strict;
use warnings;

use JSONP;

my $one = JSONP->new();
my $two = JSONP->new();

$one->thing = { a => 'b', array => [{ a => 'c' }, 3, 'hey'], meh => sub { 1 } };
$two->thing = { c => 'd', array => [{ d => 'f' }, 2 ], zzz => sub { 0 }, again => { one => 'two' }, heaven => [ 6, 6, 6 ] };

use Blessed::Merge;

my $blessed = Blessed::Merge->new();

my $new = $blessed->merge($one, $two);

is($new->thing->a, 'b');
is($new->thing->c, 'd');
is_deeply($new->thing->again, { one => 'two' });
is_deeply($new->thing->array, [{ a => 'c', d => 'f' }, 2, 'hey']);
is_deeply($new->thing->heaven, [6, 6, 6]);

my $three = bless {}, 'NotTheSame';
eval { $blessed->merge($one, $three) };
like($@, qr/Attempting to merge two different/, 'like');

$blessed = Blessed::Merge->new( { same => 0, blessed => 0 } );

$new = $blessed->merge($one, $two);

is($new->{thing}->{a}, 'b');
is($new->{thing}->{c}, 'd');
is_deeply($new->{thing}->{array}, [{ a => 'c', d => 'f' }, 2, 'hey']);

done_testing;

