package MockCrowdApp;

use warnings;
#use Data::Dump qw/dump/;
use Test::Fake::HTTPD;

our $crowd_server = Test::Fake::HTTPD->new();

$crowd_server->run( sub {
    my $req = shift;
    #warn dump($req);
    my $pass_response = '{"name":"kee","first-name":"Keerati","last-name":"Thiwanruk","display-name":"Keerati Thiwanruk","email":"keerati.th@gmail.com","active":true}';
    my $fail_response = '{"reason":"USER_NOT_FOUND","message":"User does not exist"}';
    my $denied_response = '<html><head><title>Apache Tomcat/7.0.42 - Error report</title><style><!--H1 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:22px;} H2 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:16px;} H3 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:14px;} BODY {font-family:Tahoma,Arial,sans-serif;color:black;background-color:white;} B {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;} P {font-family:Tahoma,Arial,sans-serif;background:white;color:black;font-size:12px;}A {color : black;}A.name {color : black;}HR {color : #525D76;}--></style> </head><body><h1>HTTP Status 403 - Client with address &quot;0:0:0:0:0:0:0:1&quot; is forbidden from making requests to the application, builder_auth.</h1><HR size="1" noshade="noshade"><p><b>type</b> Status report</p><p><b>message</b> <u>Client with address &quot;0:0:0:0:0:0:0:1&quot; is forbidden from making requests to the application, builder_auth.</u></p><p><b>description</b> <u>Access to the specified resource has been forbidden.</u></p><HR size="1" noshade="noshade"><h3>Apache Tomcat/7.0.42</h3></body></html>';

    if ( $req->uri =~ m/kee/ ){
        [ 200, [ 'Content-Type' => 'application/json' ], [ $pass_response ] ];
    } elsif ( $req->uri =~ m/denied/) {
        [ 403, [ 'Content-Type' => 'text/html' ], [ $denied_response ] ];
    }else {
        [ 400, [ 'Content-Type' => 'application/json' ], [ $fail_response ] ];
    }
});

1;
