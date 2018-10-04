use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More;
use Catalyst::Test 'TestAppConfig';
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
		<h3>Shortened URL: http://localhost/shorten?g=%s</h3>
		<div>
			<p><b>not</b>2</p>
			<p><b>okay</b>1</p>
		</div>
	</body
</html>|, $_) } qw/AE166 AE16g AE167 AE16h AE168/;

my $content;
for (0..4) {
	($content) = get('/shorten?okay=1&not=2');
	is($content, shift @responses, 'expected html');
}

$content = JSON->new->decode(get('/params?g=AE168'));
is_deeply($content, { okay => 1, not => 2 }, 'shorten params');

$content = JSON->new->decode(get('/extract?g=AE168&extra=1'));
is_deeply($content, { okay => 1, not => 2, extra => 1 }, 'extract with merge');

$content = JSON->new->decode(get('/extract?g=AE168&no_merge=1'));
is_deeply($content, { okay => 1, not => 2 }, 'extract without merge');

$content = request('/st/AE168');
is($content->header('location'), 'http://localhost/shorten?okay=1&not=2', 'check shorten_redirect link');

done_testing();
