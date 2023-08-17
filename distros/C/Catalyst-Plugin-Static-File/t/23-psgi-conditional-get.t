#!perl

use Test::Most;

use FindBin qw/ $Bin /;
use HTTP::Request::Common;
use Path::Tiny;
use Plack::Builder;
use Plack::Middleware::ConditionalGET;
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';
use App;

Plack::MIME->add_type( ".txt" => "text/foobar" );

my $app = builder {
    enable "ConditionalGET";
    App->psgi_app;
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

my $file = path($Bin)->child("static/hello.txt");

subtest "HTTP 200" => sub {

    my $req = GET '/?file=' . $file->basename;
    $req->if_modified_since( $file->stat->mtime - 1 );

    my $res = $mech->request($req);
    is $res->code, 200, 'GET /?file=hello.txt';

    is $res->content, $file->slurp_raw, "body";

};


subtest "HTTP 304" => sub {

    my $req = GET '/?file=' . $file->basename;
    $req->if_modified_since( $file->stat->mtime );

    my $res = $mech->request($req);
    is $res->code, 304, 'GET /?file=hello.txt';

    is $res->content, "", "no body";

};

done_testing;
