use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 7;
use Catalyst::Test 'TestApp';

{
    my $res = request('/foo/demonstrate_model');

    ok( $res->is_success, 'Test request is a success' );

    is_deeply(
        \@TestApp::Model::Foo::data,    #
        [qw( one two TestApp )],
        'Data saved ok from model'
    );
}

{
    my $res = request('/foo/demonstrate_model_with_around');

    ok( $res->is_success, 'Test request is a success' );

    is_deeply(
        \@TestApp::Model::Bar::data,    #
        [qw( one two TestApp )],
        'Data saved ok from model'
    );

    ok $TestApp::Model::Bar::BPCI_GOT_RUN, "ran local build context method";
}

{
    my $res = request('/foo/demonstrate_plugin');

    ok( $res->is_success, 'Test request is a success' );

    is_deeply(
        \@TestApp::Controller::Foo::data,
        [qw( alpha beta TestApp )],    #
        'Data saved ok from controller'
    );
}
