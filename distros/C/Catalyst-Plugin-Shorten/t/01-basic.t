use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More;
use Catalyst::Test 'TestApp';
use JSON;

my @responses = map {
	sprintf( q|<html>
	<head>
		<style>
			body {
				background: #000;
				color: #fff;
			}
		</style>
	</head>
	<body>
		<h2>Test extracting params from short url forward/detach</h2>
		<h3>Shortened URL: http://localhost/shorten?s=%s</h3>
		<div>
			<p><b>not</b>2</p>
			<p><b>okay</b>1</p>
		</div>
	</body
</html>|, $_) } qw/cc cd cf cg ch/;

my $content;
for (0..4) {
	($content) = get('/shorten?okay=1&not=2');
	is($content, shift @responses, 'expected html');
}

$content = JSON->new->decode(get('/params?s=cc'));
is_deeply($content, { okay => 1, not => 2 }, 'shorten params');

$content = JSON->new->decode(get('/extract?s=cc&extra=1'));
is_deeply($content, { okay => 1, not => 2, extra => 1 }, 'extract with merge');

$content = JSON->new->decode(get('/extract?s=cc&no_merge=1'));
is_deeply($content, { okay => 1, not => 2 }, 'extract without merge');

$content = request('/st/cc');
is($content->header('location'), 'http://localhost/shorten?okay=1&not=2', 'check shorten_redirect link');

# LONGER AKA offset
@responses = map {
	sprintf( q|<html>
	<head>
		<style>
			body {
				background: #000;
				color: #fff;
			}
		</style>
	</head>
	<body>
		<h2>Test extracting params from short url forward/detach</h2>
		<h3>Shortened URL: http://localhost/shorten?s=%s</h3>
		<div>
			<p><b>longer</b>1</p>
			<p><b>not</b>2</p>
			<p><b>okay</b>1</p>
		</div>
	</body
</html>|, $_) } qw/dygYqC dygYqD dygYqF dygYqG dygYqH/;

for (0..4) {
	$content = get('/shorten?okay=1&not=2&longer=1');
	is($content, shift @responses, 'expected html');
}

$content = request('/st/dygYqC');
is($content->header('location'), 'http://localhost/shorten?okay=1&not=2&longer=1', 'check shorten_redirect link');

$content = JSON->new->decode(get('/params?s=dygYqC'));
is_deeply($content, { okay => 1, not => 2, longer => 1 }, 'shorten params');

$content = JSON->new->decode(get('/extract?s=dygYqC&extra=1'));
is_deeply($content, { okay => 1, not => 2, longer => 1, extra => 1 }, 'extract with merge');

$content = JSON->new->decode(get('/extract?s=dygYqC&no_merge=1'));
is_deeply($content, { okay => 1, not => 2, longer => 1, }, 'extract without merge');

done_testing();
