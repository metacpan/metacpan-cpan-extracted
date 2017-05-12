use strict;
use warnings;
BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test' }
use Test::More;

use Email::Sender::Simple;
use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $response;
my $time = time;
ok( ($response = request("/email?time=$time"))->is_success, 'request ok');

my @emails = Email::Sender::Simple->default_transport->deliveries;
is( scalar @emails, 1, "got emails");
isa_ok( $emails[0]->{'email'}, 'Email::Abstract', 'email is ok' );
like($emails[0]->{'email'}->[0]->body, qr/$time/, 'Got our email');

done_testing();
