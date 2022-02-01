#!perl

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use JSON;
use File::Slurp;
use Test::LWP::UserAgent;
use App::wsgetmail::MS365::Client;
use App::wsgetmail;


my $test_config = get_test_config();
my $oauth_login_url = sprintf('https://login.windows.net/%s/oauth2/token', $test_config->{tenant_id} );
my $graph_v1_url = 'graph.microsoft.com/v1.0';
my $useragent = Test::LWP::UserAgent->new;
# map oauth request to get token
$useragent->map_response( qr{login.windows.net/} => get_mocked_token_response() );
# map folders list request/response
$useragent->map_response( qr{$graph_v1_url/me/mailFolders[^/]} => get_mocked_folders_list_response() );
# map message list request/response
$useragent->map_response( qr{$graph_v1_url/me/mailFolders/} => get_mocked_messages_response() );

*App::wsgetmail::MS365::Client::_new_useragent = sub { return $useragent };

my $getmail = App::wsgetmail->new({config => $test_config});
isa_ok($getmail, 'App::wsgetmail');
isa_ok($getmail->client, 'App::wsgetmail::MS365');

my $message1 = $getmail->get_next_message();
isa_ok($message1, 'App::wsgetmail::MS365::Message');
is($message1->id, "xxxxxxxxabc1", "first message fetched with correct id");
my $message2 = $getmail->get_next_message();
isa_ok($message2, 'App::wsgetmail::MS365::Message');
is($message2->id, "xxxxxxxxxxxxxxxxxxxxabc2=", "next message fetched with correct id");

my $message_req = $useragent->last_http_request_sent();
is($message_req->method, 'GET', 'request method is correct');
like($message_req->uri, qr{graph.microsoft.com/v1.0/me/mailFolders/AAAABBBBCCCCCDDDDDXXXXX=/messages}, 'correct uri for request');
like($message_req->uri, qr{filter=isRead\+eq\+false}, 'filter is correct');
is($message_req->header( 'Authorization' ) => 'Bearer xxxxxxxxN2tpxxxxxxxxxxxxxxxx', 'Authorisation token used correctly');

done_testing();

#####

sub get_mocked_folders_list_response {
    return HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], '{ "value": [ {
                         "displayName":"another_folder",
                         "totalItemCount":2,
                         "parentFolderId":"AABBBBBAAAAA=",
                         "childFolderCount":0,
                         "unreadItemCount":2,
                         "id":"AAAABBBBCCCCCDDDDDXXXXX="
                     } ]}');
}

sub get_mocked_token_response {
    return HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'],
                               '{"token_type":"Bearer","scope":"email Mail.Read Mail.Read.Shared Mail.ReadWrite Mail.ReadWrite.Shared openid User.Read","expires_in":"3599","ext_expires_in":"3599","expires_on":"1591286563","not_before":"1591282663","resource":"https://graph.microsoft.com/","access_token":"xxxxxxxxN2tpxxxxxxxxxxxxxxxx","refresh_token":"ABBBAAAAAAAm-xxxxx-xxxxxxxxxxxxxxx-xxx","id_token":"xxxxxxxxxxxeyJ0eXAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}'
                           );
}


sub get_mocked_messages_response {
    my $json = read_file('t/mock_responses/messages.json');
    return HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json'], $json);
}

sub get_test_config {
    return {
        "command" => 'rt-mailgate',
        "command_args" => '--url http://test.local/ --queue "general" --action correspond --debug --no-verify-ssl',
        "action_on_fetched" => "mark_as_read",
        "username" => 'rt@example.tld',
        "user_password" => "password",
        "tenant_id" => "abcd1234-xxxx-xxxx-xxxx-123abcde1234",
        "client_id" => "abcd1234-xxxx-xxxx-xxxx-1234abcdef99",
        "action_on_fetched" => "mark_as_read",
        "folder" => "Inbox"
    };
}
