#!perl

use Test::Most;

use FindBin qw/ $Bin /;
use Path::Tiny;
use Plack::Builder;
use Plack::Middleware::XSendfile;
use Test::WWW::Mechanize::PSGI;

use lib 't/lib';
use App;

Plack::MIME->add_type( ".txt" => "text/foobar" );

my $app = builder {
    enable "XSendfile",
        variation => 'X-Sendfile';
    App->psgi_app;
};

my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

my $file = path($Bin)->child("static/hello.txt")->absolute;

my $res = $mech->get( '/?file=' . $file->basename );
is $res->code, 200, 'GET /?file=hello.txt';

is $res->content, "", "no body";
is $res->header('X-Sendfile'), $file->canonpath, "X-Sendfile";

done_testing;
