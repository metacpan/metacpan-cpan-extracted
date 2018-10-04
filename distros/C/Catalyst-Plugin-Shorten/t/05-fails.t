use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More;
use Catalyst::Test 'TestApp';
use JSON;

my $content;
$content = request('/params?s=cc');
is_deeply($content->code, 500, 'invalid');

$content = request('/params?g=cc');
is_deeply($content->code, 500, 'invalid');

$content = request('/params?s=FU');
is_deeply($content->code, 500, 'invalid');

$content = request('/extract');
is_deeply($content->code, 200, 'invalid as missing s param but returns {}');
is($content->decoded_content, '{}', 'content empty {}');


done_testing();
