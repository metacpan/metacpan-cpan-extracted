use strict;
use warnings;
use Test::More;

use Datastar::SSE qw/:events/;

my $expected = "";
my $event = 'datastar-execute-script';
is( 
	Datastar::SSE->execute_script(), 
	$expected, 
	"Calling execute_script without a script to execute returns the empty string" 
);

my $script = q{console.log("Hello World!")};
$expected = join("\cM\cJ",
	"event: $event",
	"data: script $script",
	'',
	'',
);

is( 
	Datastar::SSE->execute_script( $script ), 
	$expected, 
	"Calling execute_script with a single line of JavaScript returns correctly formetted server sevent" 
);

$script = \(q{console.log("Hello World!")});
is( 
	Datastar::SSE->execute_script( $script ), 
	$expected, 
	"Calling execute_script with a single line of JavaScript as a scalar reference returns correctly formetted server sevent" 
);


my @script = (q{if (window.tmpl)}, q{console.log("tmp!")});
$script = join("\n", @script );
$expected = join("\cM\cJ",
	"event: $event",
	map("data: script $_", @script),
	'',
	'',
);

is( 
	Datastar::SSE->execute_script( $script ), 
	$expected, 
	"Calling execute_script with a multi-line JavaScript string returns script split across multiple lines" 
);

$script = [@script];
is( 
	Datastar::SSE->execute_script( $script ), 
	$expected, 
	"Calling execute_script with an arrayref of JavaScript strings returns script split across multiple lines"
);
$script = [@script];
is( 
	Datastar::SSE->execute_script( $script ), 
	$expected, 
	"Calling execute_script with an arrayref of JavaScript strings returns script split across multiple lines"
);

$script = q{console.log("Hello World!")};
my %options;

$options{ auto_remove } = 1;

$expected = join("\cM\cJ",
	"event: $event",
	"data: script $script",
	'',
	'',
);

is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with a default auto_remove (true) does not include it in the event text",
);

$options{ auto_remove } = 0;

$expected = join("\cM\cJ",
	"event: $event",
	"data: autoRemove false",
	"data: script $script",
	'',
	'',
);

is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with a false auto_remove includes the option in the event text",
);

%options = ();
$options{ attributes } = my $attributes = { type => 'module' };
my $attribute_text = 'attributes type module';

$expected = join("\cM\cJ",
	"event: $event",
	"data: script $script",
	'',
	'',
);

is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with the default attributes (as hashref) does not include attributes in the event string"
);

%options = ();
$options{ attributes } = $attributes = [{ type => 'module' }];
$attribute_text = 'attributes type module';

$expected = join("\cM\cJ",
	"event: $event",
	"data: script $script",
	'',
	'',
);

is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with the default attributes (as arrayref) does not include attributes in the event string"
);

%options = ();
$options{ attributes } = +{ type => 'script' };
$attribute_text = 'attributes type script';

$expected = join("\cM\cJ",
	"event: $event",
	"data: $attribute_text",
	"data: script $script",
	'',
	'',
);


is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with a non-default attribute (as hashref) includes attributes in the event string"
);

%options = ();
$options{ attributes } = [{ type => 'script' }];
$attribute_text = 'attributes type script';

$expected = join("\cM\cJ",
	"event: $event",
	"data: $attribute_text",
	"data: script $script",
	'',
	'',
);


is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with a non-default attribute (as arrayref) includes attributes in the event string"
);

%options = ();
$options{ attributes } = +{
	defer => 0,
	type => 'script',
	async => 0,
	
};
$expected = join("\cM\cJ",
	"event: $event",
	map( sprintf( "data: attributes %s", $_ ), "async", "defer", "type script" ),
	"data: script $script",
	'',
	'',
);


is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with multiple attributes (as hashref) includes attributes (including booleans) in the event string (sorted)"
);

%options = ();
$options{ attributes } = +[
	'defer',
	{ type => 'script' },
	'async',
];
$expected = join("\cM\cJ",
	"event: $event",
	map( sprintf( "data: attributes %s", $_ ), "defer","type script", "async", ),
	"data: script $script",
	'',
	'',
);


is( 
	Datastar::SSE->execute_script( $script, \%options ), 
	$expected, 
	"Calling execute_script with multiple attributes (as arrayref) includes attributes (including booleans) in the event string (unsorted)"
);



done_testing;
