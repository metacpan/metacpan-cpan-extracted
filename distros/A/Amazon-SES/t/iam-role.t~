use strict;
use warnings;
use Test::Modern -internet;
use MIME::Entity;
use LWP::UserAgent;
use Amazon::SES;
use VM::EC2::Security::CredentialCache;

BEGIN {
    # Try to get our credentials if it fails just skip these tests.
    my $creds;
    eval {
        alarm(10);
        $creds = VM::EC2::Security::CredentialCache->get();
    };
    if ($@ || !defined($creds)) {
        $ENV{NO_CREDS} = 1;
    }
}

SKIP: {
    skip( "Environmental variables are not set or not on an EC2 instance with an IAM role", 25)
      unless ($ENV{AWS_SES_IDENTITY} && !$ENV{NO_CREDS});

    my $ses = object_ok(
        sub {
            return Amazon::SES->new(
                use_iam_role => 1,
                from       => $ENV{AWS_SES_IDENTITY},
                region     => 'us-east-1'
            );
        },
        '$ses',
        isa => [qw(Amazon::SES)],
        can => [qw(call send verify_email delete_domain delete_email delete_identity list_emails list_domains get_quota get_statistics send_mime get_dkim_attributes region access_key secret_key use_iam_role)],
        clean => 1,
    );


    is($ses->region, 'us-east-1', "Region is: us-east-1");

    my $r;

    # Test that sending here generates an error code.
    ########## PLAIN
    $r = $ses->send(
        from      => $ENV{AWS_SES_IDENTITY} . 'asdfasdfasdf',
        to        => 'suppressionlist@simulator.amazonses.com',
        subject   => "Hello world from AWS SES",
        body      => "Hello again",
        body_html => "<h1>Салом Шоҳ</h1>",
    );

    #diag("send(): ", $r->result_as_json);
    ok( $r->is_error,         $r->error_message );
    ok( $r->request_id,       $r->request_id );
    ok( $r->error_type,       $r->error_type );
    ok( $r->http_code == 400, 'code: ' . $r->http_code );
    ok( $r->error_code,       $r->error_code );
    ok( !$r->message_id,      "Message ID does not exist" );
    ok( $r->result,           "Result set exists even for error" );

    
    ################# MIME
    my $msg = MIME::Entity->build(
        From    => $ENV{AWS_SES_IDENTITY},
        To      => 'success@simulator.amazonses.com',
        Subject => 'MIME msg from AWS SES',
        Data    => "<h1>Hello world from AWS SES</h1>",
        Type    => 'text/html'
    );
    ##### ATTACHMENTS

    my $ua = LWP::UserAgent->new();
    my $request = HTTP::Request->new(GET => 'https://www.flickr.com/photos/evapro/385650640/in/photolist-69489U-fyz13-iiy7D5-5Ja6Rm-A5yuY-57JMUp-9SZi1g-53zkrK-98NZL3-9vSoog-5zvBWg-4khc92-9yMddK-2hR4AE-A5zqy-7yrNCC-6iDNFS-jz9QM6-iVKeLo-fXRSo-e3uwEk-8juCLz-4cwiM4-4VoiFG-bNn56X-dUtpsb-sBzeE-iUdbzi-2TanKc-dhU9RW-e3Achw-e3uxQV-euq7N7-7Co3u3-7fXsS-HjErt-9xNg55-aC287b-wTsPt-akR92H-4ceCCP-dvUaij-9eRJXA-oUk4hz-TeqMG-ho1GSs-8TC8b-ouKa9x-5tnwo6-e3AcY7/');
    my $res = $ua->request($request);
    ok($res->is_success, "Successfully downloaded cat photo");
    
    $msg->attach(
        Data => $res->content,
        Type     => $res->header('Content-Type'),
        Encoding => 'base64'
    );
    $r = $ses->send($msg);
    ok( $r->is_success,
        $r->is_success ? "send_mime() success" : $r->error_message );
    ok( $r->request_id, "Request id: " . $r->request_id );
    ok( $r->result,     "Result element found" );
    ok( $r->message_id, "Message sent successfully" );
    #

    my $second_identity = $ENV{AWS_SES_IDENTITY};
    $second_identity =~ s/\@/\.test\@/;
    $r = $ses->verify_email($second_identity);

    #diag("verify_email(): ", $r->result_as_json);
    ok( $r->is_success && $r->request_id );
    $r = $ses->list_emails();

    #diag("list_emails(): ", $r->result_as_json);
    ok( $r->is_success && $r->request_id && $r->result );
    ok( @{ $r->result->{Identities} } == 2, "over two verified emails" );

    $r = $ses->list_domains();

    #diag("list_domains(): ", $r->result_as_json);
    ok( $r->is_success );
    ok( @{ $r->result->{Identities} } == 1, "One verified domain" );
    $r = $ses->delete_identity($second_identity);

    #diag("delete_identnity(): ", $r->result_as_json);
    ok( $r->is_success && $r->request_id, $r->request_id );
    $r = $ses->get_quota;

    #diag("get_quota(): ", $r->result_as_json);
    ok($r->is_success
       && $r->request_id
       && $r->result->{'Max24HourSend'} 
       && $r->result->{MaxSendRate} 
       && $r->result->{SentLast24Hours} );
    $r = $ses->get_dkim_attributes($second_identity);

    #diag("get_dkim_attributes(): " .  $r->result_as_json);
    ok( $r->is_success && !defined( $r->dkim_attributes ),
        "No Dkim attributes for this address" );
    $r = $ses->get_dkim_attributes( $ENV{AWS_SES_IDENTITY} );
    ok( $r->is_success && $r->dkim_attributes );
    $r = $ses->get_statistics();
    ok( $r->is_success );
    
    #diag("get_statistics(): ", $r->result_as_json);
} ## end SKIP:
done_testing();
