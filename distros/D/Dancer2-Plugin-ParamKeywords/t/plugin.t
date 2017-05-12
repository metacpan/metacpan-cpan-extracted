use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common qw(POST);


{
    package MyApp;
    use Dancer2 0.160003;
    use Dancer2::Plugin::ParamKeywords;

    set plugins => { 'ParamKeywords' => {   
        munge_precedence => [ qw( route query body ) ]
    } };

    any '/route/:param' => sub {
        route_param('param');
    };

    any '/query/:param' => sub {
        query_param('param');
    };

    any '/body/:param' => sub {
        body_param('param');
    };

    any '/params/:param' => sub {
        my %r = route_params;
        my %q = query_params;
        my %b = body_params;
        my @v = ($r{param}, $q{param}, $b{param});
        "@v";
    };

    any '/munged/:param' => sub {
        munged_params->{param};
    };

    any '/munged' => sub {
        munged_params->{param};
    };

    any '/munged_singular/:param' => sub {
        munged_param 'param';
    };

    any '/munged_singular' => sub {
        munged_param 'param';
    };

}

my $test = Plack::Test->create( MyApp->to_app );

subtest 'Route param' => sub {
    my $res = $test->request(
        POST '/route/foo?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'foo', 'Route returns foo' );
};

subtest 'Query param' => sub {
    my $res = $test->request(
        POST '/query/foo?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'bar', 'Query returns bar' );
};

subtest 'Body param' => sub {
    my $res = $test->request(
        POST '/body/foo?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'baz', 'Body returns baz' );
};

subtest 'All params' => sub {
    my $res = $test->request(
        POST '/params/foo?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'foo bar baz', 'All params returns foo bar baz' );
};

subtest 'Munged params route' => sub {
    my $res = $test->request(
        POST '/munged/foo?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'foo', 'Munge honors route' );
};

subtest 'Munged params query' => sub {
    my $res = $test->request(
        POST '/munged?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'bar', 'Munge honors query' );
};

subtest 'Munged params body' => sub {
    my $res = $test->request(
        POST '/munged', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'baz', 'Munge honors body' );
};

subtest 'Munged param route' => sub {
    my $res = $test->request(
        POST '/munged_singular/foo?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'foo', 'Munge singular honors route' );
};

subtest 'Munged param query' => sub {
    my $res = $test->request(
        POST '/munged_singular?param=bar', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'bar', 'Munge singular honors query' );
};

subtest 'Munged param body' => sub {
    my $res = $test->request(
        POST '/munged_singular', Content => [ param => 'baz' ]
    );

    is( $res->decoded_content, 'baz', 'Munge singular honors body' );
};


done_testing;
