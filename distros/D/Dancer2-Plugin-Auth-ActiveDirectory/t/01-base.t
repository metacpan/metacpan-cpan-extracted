#!perl -T
use strict;
use warnings;
use Plack::Test;
use Test::More import => ['!pass'];
use HTTP::Request::Common qw(GET POST);
use lib '.';

eval { require Auth::ActiveDirectory };
if ($@) {
    plan skip_all => 'Auth::ActiveDirectory required to run these tests';
}

use t::lib::TestApp;
my $app = t::lib::TestApp->to_app;
is( ref $app, "CODE", "Got a code ref" );
test_psgi $app, sub {
    my $cb = shift;

    {
        my $res = $cb->( POST '/login/mziescha/test_pass' );
        is $res->content, 1, 'login fires';
    }

    {
        my $res = $cb->( POST '/list_user/dsonnta/test_pass/test' );
        is $res->content, 0, 'list_user fires';
    }

    {
        my $res = $cb->( POST '/list_user/dsonnta/test_pass' );
        is $res->content, 2, 'list_user fires';
    }

    {
        my $res = $cb->( GET '/rights/git' );
        is $res->content, '["ad_check","ad_test"]', 'rights fires';
    }

    {
        my $res = $cb->( GET '/rights_by_user/dsonnta/test_pass' );
        is $res->content, '{"test":1}', 'list_user fires';
    }

    {
        my $res = $cb->( GET '/authenticate_config/domain' );
        is $res->content, '{"domain":"example"}', 'list_user fires';
    }

    {
        my $res = $cb->( GET '/has_right/dsonnta/test_pass/test' );
        is $res->content, 1, 'list_user fires';
    }

    {
        my $res = $cb->( GET '/has_right/mziescha/test_pass/check' );
        is $res->content, 0, 'list_user fires';
    }

};

done_testing();

__END__



