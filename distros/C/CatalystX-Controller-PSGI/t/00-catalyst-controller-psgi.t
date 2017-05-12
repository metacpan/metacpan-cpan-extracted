use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More tests => 5;
use Catalyst::Test 'TestApp';

my $actions;
subtest 'normal actions' => sub {
    plan tests => 5;

    my $res = request('/ascii/');
    ok( $res->is_success, "/ascii/ is succcess" );
    is( $res->decoded_content, 'sub index: Private content', "sub index: Private works" );

    my $c;
    ( $res, $c ) = ctx_request('/ascii/other');
    ok( $res->is_success, "/ascii/other is succcess" );
    is( $res->decoded_content, 'normal controller methods work as well!', "normal controller action" );

    foreach my $action ( keys %{$c->dispatcher->_action_hash} ) {
        next if $action =~ m{\w+/_(?:ACTION|END|DISPATCH|AUTO|BEGIN)};
        $actions->{ $action } = $c->dispatcher->_action_hash->{ $action };
    }
    is( keys %{$actions}, 6, '6 actions' );
};

subtest 'file/call' => sub {
    plan tests => 3;

    my $content;
    {
        open my $fh, '<', $INC{'TestApp/Controller/File.pm'};
        local $/;
        undef $/;
        $content = <$fh>;
        close $fh;
    }

    my $res = request('/file/');
    ok( $res->is_success, "response is succcess" );
    is( $res->decoded_content, $content, 'content is correct' );

    subtest 'action' => sub {
        plan tests => 5;

        my $call = $actions->{'file/call'};

        is( $call->reverse, 'file/', 'reverse' );
        is( $call->namespace, 'file', 'namespace' );
        is( $call->name, 'call', 'name' );
        is( $call->class, 'TestApp::Controller::File', 'class' );
        is_deeply( $call->attributes, { Path => ['file/'] }, 'attributes' );
    };
};

subtest '/ascii/lol/copter' => sub {
    plan tests => 3;

    my ( $res, $c ) = ctx_request('/ascii/lol/copter');

    ok( $res->is_success, "response is succcess" );
    is( $res->decoded_content, $c->controller('Ascii')->lolcopter, "content is correct" );

    subtest 'action' => sub {
        plan tests => 5;

        my $call = $actions->{'ascii/lol/copter'};

        is( $call->reverse, 'ascii/lol/copter', 'reverse' );
        is( $call->namespace, 'ascii', 'namespace' );
        is( $call->name, 'lol/copter', 'name' );
        is( $call->class, 'TestApp::Controller::Ascii', 'class' );
        is_deeply( $call->attributes, { Path => ['ascii/lol/copter'] }, 'attributes' );
    };
};

subtest '/ascii/not/copter' => sub {
    plan tests => 3;

    my ( $res, $c ) = ctx_request('/ascii/not/copter');

    ok( $res->is_success, "response is succcess" );
    is( $res->decoded_content, "totally not a lolcopter", "content is correct" );

    subtest 'action' => sub {
        plan tests => 5;

        my $call = $actions->{'ascii/not/copter'};

        is( $call->reverse, 'ascii/not/copter', 'reverse' );
        is( $call->namespace, 'ascii', 'namespace' );
        is( $call->name, 'not/copter', 'name' );
        is( $call->class, 'TestApp::Controller::Ascii', 'class' );
        is_deeply( $call->attributes, { Path => ['ascii/not/copter'] }, 'attributes' );
    };
};

subtest '/ascii/hypnotoad' => sub {
    plan tests => 3;

    my ( $res, $c ) = ctx_request('/ascii/hypnotoad');

    ok( $res->is_success, "response is succcess" );
    is( $res->decoded_content, $c->controller('Ascii')->hypnotoad, "content is correct" );

    subtest 'action' => sub {
        plan tests => 5;

        my $call = $actions->{'ascii/hypnotoad'};

        is( $call->reverse, 'ascii/hypnotoad', 'reverse' );
        is( $call->namespace, 'ascii', 'namespace' );
        is( $call->name, 'hypnotoad', 'name' );
        is( $call->class, 'TestApp::Controller::Ascii', 'class' );
        is_deeply( $call->attributes, { Path => ['ascii/hypnotoad'] }, 'attributes' );
    };
};
