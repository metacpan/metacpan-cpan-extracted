use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw/ $Bin /;

use File::Temp qw/ tempfile /;
use File::Which qw/ which /;
use HTTP::Request::Common;
use HTTP::Status qw/ :constants /;
use WWW::Mechanize::Chrome;

plan skip_all => "Cannot find a chrome executable" unless WWW::Mechanize::Chrome->find_executable;

use lib 't/lib';
use Catalyst::Test 'App';

my ($res, $c) = ctx_request( GET '/' );

is $res->code, HTTP_OK, 'status code';

is $res->content_type, 'application/pdf', 'content_type';

ok my $data = $res->decoded_content, 'decoded_content';

cmp_deeply $c->log->msgs, [ { level => 'debug', message => re('^Saving the HTML to ') } ], 'log messages from ChromePDF'
  or diag(explain [ $c->log->msgs ] );

done_testing;
