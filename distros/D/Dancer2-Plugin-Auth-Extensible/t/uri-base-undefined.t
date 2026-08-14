use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

# Tests to ensure that the host of the request is used to generate links in
# emails, when uri_base is not defined.

BEGIN {
    eval "require Mail::Message";
    plan skip_all => 'Mail::Message is not installed'
        if $@;

    eval "require Mail::Transport::Sendmail";
    plan skip_all => 'Mail::Transport is not installed'
        if $@;

    $ENV{DANCER_CONFDIR}     = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'uri-base-undefined';
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

# For each host request, the host name should be in the email sent
foreach my $host (qw/application-host-1.example.com application-host-2.example.com/)
{
    # Send a password reset email
    my $req = GET "http://$host/send_password_reset";
    my $res = $test->request($req);

    is $res->code, 200,
      "Successful response when requesting password reset";

    like $message_sent->string, qr/\Q$host/, "Password reset email contains URL";
    undef $message_sent;

    # Create a user sending a welcome email
    $req = GET "http://$host/create_user/$host";
    $res = $test->request($req);

    is $res->code, 200,
      "Successful response when requesting password reset";

    like $message_sent->string, qr/\Q$host/, "Password reset email contains URL";
    undef $message_sent;
}

done_testing;
