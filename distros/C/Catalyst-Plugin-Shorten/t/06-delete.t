use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More;
use Catalyst::Test 'TestApp';

get('/shorten?okay=1') for 0..1;

my $content;

$content = get('/params?s=cc');
is($content, '{"okay":"1"}', 'content exists');

$content = get('/delete?s=cc');
is($content, 'deleted cc', 'deleted via params');

$content = request('/delete?g=cc');
is($content->code(), 500, 'now it does not');

$content = request('/params?s=cc');
is($content->code(), 500, 'now it does not');

$content = get('/params?s=cd');
is($content, '{"okay":"1"}', 'content exists');

$content = get('/ddelete/cd');
is($content, 'deleted cd', 'deleted via params');

$content = request('/params?s=cd');
is($content->code(), 500, 'now it does not');

done_testing();
