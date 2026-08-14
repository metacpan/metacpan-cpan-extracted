use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

# Tests to ensure that uri_base is always used when defined, whatever the host
# of the request. Needs to be a different test to uri-base-undefined.t as a
# different config is used.

BEGIN {
    eval "require Mail::Message";
    plan skip_all => 'Mail::Message is not installed'
        if $@;

    eval "require Mail::Transport::Sendmail";
    plan skip_all => 'Mail::Transport is not installed'
        if $@;

    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'uri-base-defined';

}

use lib 't/lib';
use TestApp::Emails;

my $message_sent;

{
    # Function to catch the content of emails sent
    no warnings 'redefine';
    *Mail::Transport::Sendmail::trySend = sub ($@) {
        my ($mailer, $msg, %options) = @_;
        $message_sent = $msg;
        return (1, undef, undef, undef, undef, "queued");
    };
}

my $app = Dancer2->runner->psgi_app;
is(ref $app, 'CODE', 'Got app');

my $test = Plack::Test->create($app);
my $host = "malicious.example.com";

# Send a password reset email
{
    my $req = GET "http://$host/send_password_reset";
    my $res = $test->request($req);

    is $res->code, 200,
      "Successful response when requesting password reset";

    like $message_sent->string, qr/\Qgenuine.example.com/, "Password reset email contains base_uri";
    unlike $message_sent->string, qr/malicious/, "Password reset email does not contain malicious host";
    undef $message_sent;
}

# Create a user sending a welcome email
{
    my $req = GET "http://$host/create_user/$host";
    my $res = $test->request($req);

    is $res->code, 200,
      "Successful response when requesting password reset";

    like $message_sent->string, qr/\Qgenuine.example.com/, "Password reset email contains URL";
    unlike $message_sent->string, qr/malicious/, "Password reset email does not contain malicious host";
    undef $message_sent;
}

done_testing;
