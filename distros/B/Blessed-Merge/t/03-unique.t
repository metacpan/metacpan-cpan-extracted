use Test::More;

use strict;
use warnings;

use JSONP;

#my ($one, $two) = JSONP->new() x 2;
my $one = JSONP->new();
my $two = JSONP->new();
my $three = JSONP->new();
my $four = JSONP->new();
my $five = JSONP->new();
$one->thing = { array => ['that', 'thing'] };
$two->thing = { array => ['thing', 'other', 'thing'] };
$three->thing = { array => [['thing'], { okay => 1 }] };
$four->thing = { op => {}, array => [{}], ah => [{}], kkk => [{}]};
$five->thing = { op => [], array => [{}], ah => [[]], kkk => [] };

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

$new = $blessed->merge($one, $two, $three);
is($new->thing->serialize, '{"array":["that",["thing"],"thing",{"okay":1},"other"]}');

$new = $blessed->merge($four, $five);
is($new->thing->ah->serialize, '[{},[]]');
is($new->thing->array->serialize, '[{}]');
is($new->thing->kkk->serialize, '[{}]');
is($new->thing->op->serialize(), '{}');
done_testing;

