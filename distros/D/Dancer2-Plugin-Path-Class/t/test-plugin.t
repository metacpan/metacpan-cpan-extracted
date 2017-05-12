use strict;
use warnings;

use Test::More tests => 3;
use Plack::Test;
use HTTP::Request::Common;
use Path::Tiny;

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Path::Class;

    get '/' => sub { return "homepage" };

    get '/public' => sub {
        my $dir = ls( config->{public_dir} );
        return join( ",",
            $dir, var('ls_name'),
            var('ls_dirs')->[0]->{file_count},
            scalar @{ var('ls_files') } );
    };

    get '/img' => sub {
        my $dir = ls( config->{public_dir}, '/img' );
        use Data::Dumper;
        return join( ",",
            $dir, var('ls_name'),
            scalar @{ var('ls_dirs') },
            scalar @{ var('ls_files') } );
    };
};

my $test = Plack::Test->create( TestApp->to_app );

my $public_dir = path('t/public');
my $img_dir    = path('t/public/img');

subtest 'get /' => sub {
    plan tests => 2;

    my $res = $test->request( GET "/" );

    ok $res->is_success, "get / is OK";

    is $res->code, 200, "get / code is 200";
};

subtest 'get /public' => sub {
    plan tests => 3;

    my $res = $test->request( GET "/public" );

    ok $res->is_success, "get /public is OK";

    is $res->code, 200, "get /public code is 200";

    is $res->content,
      join( ",", $public_dir->absolute->canonpath, 'public,3,0' ),
      "content is correct";

};

subtest 'get /img' => sub {
    plan tests => 3;

    my $res = $test->request( GET "/img" );

    ok $res->is_success, "get /img is OK";

    is $res->code, 200, "get /img code is 200";

    is $res->content, join( ",", $img_dir->absolute->canonpath, 'img,0,3' ),
      "content is correct";

};
