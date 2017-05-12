use strict;
use warnings;

BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }
use Test::More;
use Test::Requires {
    'Catalyst::View::TT' => '0.31',
};
use Email::Sender::Simple;
use FindBin;
use lib "$FindBin::Bin/lib";
use Data::Dump qw(ddx);
use_ok('Catalyst::Test', 'TestApp');

my $response;
my $response2;
my $time = time;
ok( ( $response = request("/template_email?time=$time"))->is_success,
    'request ok' );
my @emails = Email::Sender::Simple->default_transport->deliveries;
like( $response->content, qr/Template Email Ok/, 'controller says ok' );
cmp_ok(@emails, '==', 1, 'got emails');
isa_ok( $emails[0]->{'email'}, 'Email::Abstract', 'email is ok' );

like($emails[0]->{'email'}[0]->header("Content-type"), qr#^multipart/alternative#, 'Multipart email');

my @parts = $emails[0]->{'email'}[0]->parts;
cmp_ok(@parts, '==', 2, 'got parts');

is($parts[0]->content_type, 'text/plain', 'text/plain part ok');
like($parts[0]->body, qr/test-email\@example.com on $time/, 'got content back');

is($parts[1]->content_type, 'text/html', 'text/html ok');
like($parts[1]->body, qr{<em>test-email\@example.com</em> on $time}, 'got content back');

ok( ( $response2 = request("/template_email_single?time=$time"))->is_success,
    'request ok' );
like( $response2->content, qr/Template Email Ok/, 'controller says ok' );
my @emails2 = Email::Sender::Simple->default_transport->deliveries;
my @parts2 = $emails2[0]->{'email'}[0]->parts;
is($parts2[1]->content_type, 'text/html', 'text/html ok');
like($parts2[1]->body, qr{<em>test-email\@example.com</em> on $time}, 'got content back');
done_testing();
