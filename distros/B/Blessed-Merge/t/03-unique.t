use Test::More;

use strict;
use warnings;

use JSONP;

my $one = JSONP->new();
my $two = JSONP->new();

$one->thing = { array => ['that', 'thing'] };
$two->thing = { array => ['thing', 'other', 'thing'] };

$one->other = {
	a => {
		b => "c",
		d => "e",
	},
	b => [qw/a c e/],
};

$two->other = {
	a => {
		b => 100,
		d => 200,
		z => 300,
	},
	b => [qw/b d f/],
	c => 'thing',
};

use Blessed::Merge;

my $blessed = Blessed::Merge->new({ unique_array => 1, unique_hash => 1 });

my $new = $blessed->merge($one, $two);

is($new->thing->serialize, '{"array":["that","thing","other"]}');
is($new->other->b->serialize, '["a","b","c","d","e","f"]');
is($new->other->a->b, 'c');
is($new->other->c, 'thing');

done_testing;

