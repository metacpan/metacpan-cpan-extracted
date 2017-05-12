#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use Dancer::FileUtils 'path';

use_ok 'Dancer::Template::Semantic';

my $engine;
eval { $engine = Dancer::Template::Semantic->new };
is $@, '', "Dancer::Template::Semantic engine created";

my $template = path('t', 'index.html');

my $result = $engine->render(
	$template,
	{
		'title'   => 'Testing, Testing... Testing?',
		'#header' => 'These are a few of my favourite things',
		'//a[@id="link"]/@href' => 'http://perl.org'
	}
);


# Future note: When you expand the tests, modify $expected.
# diag $result;

my $expected = <<HTML;
<html xmlns="http://www.w3.org/1999/xhtml">
<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title>Testing, Testing... Testing?</title>
</head>
<body>
	<h1 id="header">These are a few of my favourite things</h1>
	<div class="container">
		<a id="link" href="http://perl.org"></a>
	</div>
</body>
</html>
HTML

is $result, $expected, 'Output matches changes.';
