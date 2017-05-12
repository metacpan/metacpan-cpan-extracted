use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 4, have_lwp;

# some mod_dav URL
my $url = '/parse/EPD%20Lookup/lots%201-66,%20A-G.txt';

my $response = GET $url, username => 'geoff', password => 'geoff';

ok $response->code == 200;
ok $response->content eq q!/parse/EPD%20Lookup/lots%201-66,%20A-G.txt!;

$url = '/parse/emb=edded+stuff&other$garble';

$response = GET $url, username => 'geoff', password => 'geoff';

ok $response->code == 200;
ok $response->content eq q!/parse/emb=edded+stuff&other$garble!;
