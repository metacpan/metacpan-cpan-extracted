use strict;
use warnings;
use Test::More;

use Datastar::SSE qw/:events/;

my $expected = "";
my $event = 'datastar-remove-signals';
is( 
	Datastar::SSE->remove_signals(), 
	$expected, 
	"Calling remove_signals without specifying signals returns the empty string" 
);

my @signals = qw/foo bar.baz/;
$expected = join("\cM\cJ",
	"event: $event",
	'data: paths foo',
	'data: paths bar.baz',
	'',
	'',
);

is( 
	Datastar::SSE->remove_signals( @signals ),
	$expected, 
	"Calling remove_signals with signals specified as an list returns correct event string",
);

@signals = ([@signals]);
is( 
	Datastar::SSE->remove_signals( @signals ),
	$expected, 
	"Calling remove_signals with signals specified as an array reference returns correct event string",
);

done_testing;
