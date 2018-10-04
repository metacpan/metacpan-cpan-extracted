use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::More;
use Catalyst::Test 'TestApp';
use JSON;

my $content;
($content) = get('/link_url');
is($content, 'http://localhost/extract?s=cc', 'expected html');

$content = JSON->new->decode(get($content));
is_deeply($content, { okay => 1, not => 2, random => 3 }, 'shorten params');

done_testing();
