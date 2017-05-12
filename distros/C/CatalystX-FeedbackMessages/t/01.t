use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use_ok('Catalyst::Test', 'TestApp');
my $response;
ok( ($response = request("/has_message"))->is_success, 'request ok');
like( $response->content, qr/Test/, 'Test is in stash' );
my $response2;
ok( ($response2 = request("/no_message"))->is_success, 'request ok');
like( $response2->content, qr/No messages/, 'Test is not in stash' );
my $response3;
ok( ($response3 = request("/many_messages"))->is_success, 'request ok');
like( $response3->content, qr/One, Two, Three/, 'Three messages found' );

done_testing;