use strict;
use warnings;
use Test::More;
use Test::Requires 'Locale::Maketext::Lexicon', 'Locale::Maketext::Simple';

use FindBin;
use lib "$FindBin::Bin/plugin_i18n/lib";

use Ark::Test 'TestApp::SubApp';
use HTTP::Request::Common;

my $req = GET '/hello';
$req->header('Accept-Language' => 'ja' );

my $res = request $req;

is $res->code, '200';
is $res->content, 'こんにちは';

done_testing;

