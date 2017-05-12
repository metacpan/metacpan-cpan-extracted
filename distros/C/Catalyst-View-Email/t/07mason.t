use strict;
use warnings;
use Test::More;
use Test::Requires {
    'Catalyst::View::Mason' => '0.18',
};

##
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }
use FindBin;
use lib "$FindBin::Bin/lib";

use Email::Sender::Simple;

use_ok('Catalyst::Test', 'TestApp');

TestApp->config->{default_view} = 'Mason';
my $response;
my $time = time;
ok( ( $response = request("/mason_email?time=$time"))->is_success,
    'request ok' );
like( $response->content, qr/Mason Email Ok/, 'controller says ok' );
my @emails = Email::Sender::Simple->default_transport->deliveries;
cmp_ok(@emails, '==', 1, 'got emails');
isa_ok( $emails[0]->{'email'}, 'Email::Abstract', 'email is ok' );
my @parts = $emails[0]->{'email'}[0]->parts;
cmp_ok(@parts, '==', 2, 'got parts');
is($parts[0]->content_type, 'text/plain', 'text/plain ok');
like($parts[0]->body, qr/test-email\@example.com on $time/, 'got content back');
is($parts[1]->content_type, 'text/html', 'text/html ok');
like($parts[1]->body, qr{<em>test-email\@example.com</em> on $time}, 'got content back');
#like($emails[0]->body, qr/$time/, 'Got our email');
done_testing();
