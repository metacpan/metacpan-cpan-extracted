use strict;
use warnings;
use Test::Modern qw(-internet -extended);
use MIME::Entity;
use LWP::UserAgent;
use Amazon::SES;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SES;
use VM::EC2::Security::CredentialCache;

BEGIN {
    # Try to get our credentials if it fails just skip these tests.
    my $creds;
    eval {
        alarm(4);
        $creds = VM::EC2::Security::CredentialCache->get();
    };
    if ($@ || !defined($creds)) {
        $ENV{NO_CREDS} = 1;
    }
}

SKIP: {
    skip( "Environmental variables are not set or not on an EC2 instance with an IAM role", 2)
      unless ($ENV{AWS_SES_IDENTITY} && !$ENV{NO_CREDS});

    
    my $transport = Email::Sender::Transport::SES->new(use_iam_role => 1);
    ok(defined($transport), "Transport is defined");

    my $email = Email::Simple->create(
        header => [
            To => 'successlist@simulator.amazonses.com',
            From => $ENV{AWS_SES_IDENTITY},
            Subject => "test subject"
        ],
        body => "test_message"
    );
    my $r = sendmail($email, { transport => $transport});
    ok(defined($r), "Send was ok");

} ## end SKIP:
done_testing();
