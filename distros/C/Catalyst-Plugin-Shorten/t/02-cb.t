use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More;
use Catalyst::Test 'TestApp';
use JSON;

my $content;
($content) = get('/cb_shorten?okay=1&not=2');
is($content, 'cc', 'expected html');

$content = JSON->new->decode(get('/cb_params?s=cc&user=me'));
is_deeply($content, { okay => 1, not => 2 }, 'shorten params');

$content = JSON->new->decode(get('/cb_extract?s=cc&user=me'));
is_deeply($content, { okay => 1, not => 2, user => 'me' }, 'extract with merge');

$content = request('/cb_redirect/cc?user=me');
is($content->header('location'), 'http://localhost/cb_shorten?okay=1&not=2', 'check shorten_redirect link');

$content = request('/cb_params?s=cc&user=not');
is($content->code, 500, 'cb returned undef');

$content = request('/cb_extract?s=cc&user=not');
is($content->code, 500, 'cb returned undef');

$content = request('/cb_redirect/cc?user=not');
is($content->code, 500, 'cb returned undef');


done_testing();
