use strict;
use warnings;
use Test::More;

use Datastar::SSE qw/:events/;

my $expected = "";
my $event = 'datastar-remove-fragments';
is( 
	Datastar::SSE->remove_fragments(), 
	$expected, 
	"Calling remove_fragments without a selector specified returns the empty string" 
);

my $selector = '#foo';
$expected = join("\cM\cJ",
	"event: $event",
	"data: selector $selector",
	'',
	'',
);

is( 
	Datastar::SSE->remove_fragments( $selector ), 
	$expected, 
	"Calling remove_fragments with a selector returns correct event string",
);



done_testing;
