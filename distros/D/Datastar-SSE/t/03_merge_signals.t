use strict;
use warnings;
use Test::More;

use Datastar::SSE qw/:events/;

my $expected = "";
my $event = 'datastar-merge-signals';
is( 
	Datastar::SSE->merge_signals(), 
	$expected, 
	"Calling merge_signals without specifying signals returns the empty string" 
);

my $signals = +{ foo => { bar => 1 }};
$expected = join("\cM\cJ",
	"event: $event",
	'data: signals {"foo":{"bar":1}}',
	'',
	'',
);

is( 
	Datastar::SSE->merge_signals( $signals ), 
	$expected, 
	"Calling merge_signals with signals specified returns correct event string",
);

my $options = {};
$options->{only_if_missing} = 0;

$expected = join("\cM\cJ",
	"event: $event",
	'data: onlyIfMissing false',
	'data: signals {"foo":{"bar":1}}',
	'',
	'',
);

is( 
	Datastar::SSE->merge_signals( $signals, $options ), 
	$expected, 
	"Calling merge_signals with signals specified and only_if_missing option set (false) returns correct event string",
);

$options->{only_if_missing} = 1;

$expected = join("\cM\cJ",
	"event: $event",
	'data: onlyIfMissing true',
	'data: signals {"foo":{"bar":1}}',
	'',
	'',
);

is( 
	Datastar::SSE->merge_signals( $signals, $options ), 
	$expected, 
	"Calling merge_signals with signals specified and only_if_missing option set (true) returns correct event string",
);

done_testing;
