use Test::More;

use strict;
use warnings;

use lib 't/lib';

use EmailTest;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my $app = EmailTest->to_app;
isa_ok $app, 'CODE', 'EmailTest app';

my $test = Plack::Test->create( $app );

my $res = $test->request( GET '/contact' );
ok $res->is_success, "GET /contact request is_success";
like $res->content,  qr'Email sent.',
  "... and response is 'Email sent.' as expected.";

done_testing;
