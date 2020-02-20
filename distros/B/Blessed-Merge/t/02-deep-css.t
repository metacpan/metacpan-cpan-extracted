use Test::More;

use strict;
use warnings;

use JSONP;

my $one = JSONP->new();
my $two = JSONP->new();

$one->css = { 
	'@media only screen (min-width: 33.75em)' => {
		'.container' => {
			'width' => '80%'
		}
	}
};

$two->css = { 
	'@media only screen (min-width: 33.75em)' => {
		'.container' => {
			'width' => '100%',
		}
	}
};

use Blessed::Merge;

my $blessed = Blessed::Merge->new();

my $new = $blessed->merge($one, $two);

delete $new->{error}; # waiting for Mussolini to fix his shiz
is($new->serialize, '{"css":{"@media only screen (min-width: 33.75em)":{".container":{"width":"100%"}}}}');

my $unique = Blessed::Merge->new( unique_hash => 1 );
$unique = $unique->merge($one, $two);

delete $new->{error}; 
is($unique->serialize, '{"css":{"@media only screen (min-width: 33.75em)":{".container":{"width":"80%"}}}}');





done_testing;

