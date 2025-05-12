use strict;
use warnings;
use Test::More;

use Datastar::SSE qw/:events :fragment_merge_modes/;

my $expected = "";
my $event = 'datastar-merge-fragments';
my %options;
is( 
	Datastar::SSE->merge_fragments(), 
	$expected, 
	"Calling merge_fragments without a fragment specified returns the empty string" 
);

my $fragment = '<div id="foo">Hello, world</div>';
$expected = join("\cM\cJ",
	"event: $event",
	"data: fragments $fragment",
	'',
	'',
);

is( 
	Datastar::SSE->merge_fragments( $fragment ), 
	$expected, 
	"Calling merge_fragments with a single line of HTML returns correctly formetted server sevent" 
);

$fragment = \'<div id="foo">Hello, world</div>';
is( 
	Datastar::SSE->merge_fragments( $fragment ), 
	$expected, 
	"Calling merge_fragments with a single line of HTML as a scalar reference returns correctly formetted server sevent" 
);


my @fragment = ("<div>","<span>Hello!</span>","</div>");
$fragment = join("\n", @fragment );
$expected = join("\cM\cJ",
	"event: $event",
	map("data: fragments $_", @fragment),
	'',
	'',
);

is( 
	Datastar::SSE->merge_fragments( $fragment ), 
	$expected, 
	"Calling merge_fragments with a multi-line HTML string returns fragment split across multiple lines" 
);

$fragment = [@fragment];
is( 
	Datastar::SSE->merge_fragments( $fragment ), 
	$expected, 
	"Calling merge_fragments with an arrayref of HTML strings returns fragment split across multiple lines"
);
$fragment = [@fragment];
is( 
	Datastar::SSE->merge_fragments( $fragment ), 
	$expected, 
	"Calling merge_fragments with an arrayref of HTML strings returns fragment split across multiple lines"
);

$fragment = '<div>Greetings</div>';

$options{ use_view_transition } = 0;

$expected = join("\cM\cJ",
	"event: $event",
	"data: fragments $fragment",
	'',
	'',
);

is( 
	Datastar::SSE->merge_fragments( $fragment, \%options ), 
	$expected, 
	"Calling merge_fragments with a default use_view_transition (false) does not include it in the event text",
);

$options{ use_view_transition } = 1;

$expected = join("\cM\cJ",
	"event: $event",
	"data: useViewTransition true",
	"data: fragments $fragment",
	'',
	'',
);

is( 
	Datastar::SSE->merge_fragments( $fragment, \%options ), 
	$expected, 
	"Calling merge_fragments with a truthy use_view_transition includes the option in the event text",
);

%options = ();
$options{ selector } = my $selector = '#selector'; 

$expected = join("\cM\cJ",
	"event: $event",
	"data: selector $selector",
	"data: fragments $fragment",
	'',
	'',
);

is( 
	Datastar::SSE->merge_fragments( $fragment, \%options ), 
	$expected, 
	"Calling merge_fragments with a selector option includes selector in the event text",
);

%options = ();
$options{ merge_mode } = 'notvalid';

$expected = join("\cM\cJ",
	"event: $event",
	"data: fragments $fragment",
	'',
	'',
);


is( 
	Datastar::SSE->merge_fragments( $fragment, \%options ), 
	$expected, 
	"Calling merge_fragments with an invalid merge_mode does not include it in the event text",
);

%options = ();
$options{ merge_mode } = my $merge_mode =  FRAGMENT_MERGEMODE_MORPH;

$expected = join("\cM\cJ",
	"event: $event",
	"data: fragments $fragment",
	'',
	'',
);


is( 
	Datastar::SSE->merge_fragments( $fragment, \%options ), 
	$expected, 
	"Calling merge_fragments with default merge_mode (morph) does not include it in the event text",
);


$options{ merge_mode } = $merge_mode =  FRAGMENT_MERGEMODE_INNER;

$expected = join("\cM\cJ",
	"event: $event",
	"data: mergeMode $merge_mode",
	"data: fragments $fragment",
	'',
	'',
);


is( 
	Datastar::SSE->merge_fragments( $fragment, \%options ), 
	$expected, 
	"Calling merge_fragments with merge_mode includes mergeMode in the event text",
);


done_testing;
