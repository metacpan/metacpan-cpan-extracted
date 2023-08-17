#!perl

use Test::Most;

use FindBin qw/ $Bin /;
use HTTP::Request::Common;
use HTTP::Status qw/ :constants /;
use Path::Tiny;

use lib 't/lib';
use Catalyst::Test 'App';

subtest "file" => sub {

    my $file = path($Bin)->child("static/hello.txt");

    my $res = request( GET '/?file=' . $file->basename );
    is $res->code,            HTTP_OK,            "status";
    is $res->content_type,    "text/plain",       "content_type";
    is $res->content_length,  $file->stat->size,  "content_length";
    is $res->last_modified,   $file->stat->mtime, "last_modified";
    is $res->decoded_content, $file->slurp_raw,   "content";
};

subtest "file with type" => sub {

    my $file = path($Bin)->child("static/hello.txt");

    my $res = request( GET '/?type=foo/bar&file=' . $file->basename );
    is $res->code,            HTTP_OK,            "status";
    is $res->content_type,    "foo/bar",          "content_type";
    is $res->content_length,  $file->stat->size,  "content_length";
    is $res->last_modified,   $file->stat->mtime, "last_modified";
    is $res->decoded_content, $file->slurp_raw,   "content";
};

subtest "bad file" => sub {

    my $file = path($Bin)->child("static/hello.txt.bad");

    my ( $res, $c ) = ctx_request( GET '/?file=' . $file->basename );
    is $res->code, HTTP_INTERNAL_SERVER_ERROR, "status (expected error)";

    my $abs = $file->absolute->canonpath;
    my $msg = "Unable to open ${abs} for reading: No such file or directory";

    cmp_deeply $c->log->msgs,
      [
        {
            level   => "error",
            message => all( isa('Catalyst::Exception'), methods( message => re( "^" . quotemeta($msg) ) ) ),
        }
      ],
      "logged exception";

};

done_testing;
