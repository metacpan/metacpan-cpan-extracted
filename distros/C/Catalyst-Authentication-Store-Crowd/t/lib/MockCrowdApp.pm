package MockCrowdApp;

use warnings;
use Test::Fake::HTTPD;

our $crowd_server = Test::Fake::HTTPD->new();

$crowd_server->run( sub {
    my $req = shift;
    my $pass_response = '{"name":"kee","first-name":"Keerati","last-name":"Thiwanruk","display-name":"Keerati Thiwanruk","email":"keerati.th@gmail.com","active":true}';
    my $fail_response = '{"reason":"USER_NOT_FOUND","message":"User does not exist"}';

    if ( $req->uri =~ m/kee/ ){
        [ 200, [ 'Content-Type' => 'application/json' ], [ $pass_response ] ];
    } else {
        [ 400, [ 'Content-Type' => 'application/json' ], [ $fail_response ] ];
    }
});

1;
