use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use JSON::MaybeXS;

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::TemplateFlute;

    set log    => 'debug';
    set logger => 'console';

    sub form_to_json {
        my $form = shift;
        return to_json(
            {
                action   => $form->action,
                errors   => $form->errors->mixed,
                fields   => $form->fields,
                name     => $form->name,
                pristine => $form->pristine,
                session  => $form->session->read('form'),
                valid    => $form->valid,
                values   => $form->values->mixed,
            },
            { canonical => 1 }
        );
    }

    get '/checkout' => sub {
        my $form = form(
            action => '/checkout',
            name   => 'checkout',
            source => 'session'
        );
        $form->set_fields( [ 'one', 'two' ] );
        return form_to_json($form);
    };

    post '/checkout' => sub {
        my $form = form( name => 'checkout', source => 'body' );
        return form_to_json($form);
    };

    post '/checkout_add_error' => sub {
        my $form = form( name => 'checkout', source => 'body' );
        $form->add_error( one => 'looks dodgy' );
        return form_to_json($form);
    };

}

my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create( TestApp->to_app );

my ( $data, $res, $req );

subtest 'get checkout' => sub {
    $res = $test->request( GET "$url/checkout" );
    ok $res->is_success, "GET /checkout successful" or diag explain $res;
    $jar->extract_cookies($res);
    is exception { $data = decode_json( $res->content ) }, undef, "decode json";

    cmp_deeply $data,
      {
        action   => '/checkout',
        errors   => {},
        fields   => [ 'one', 'two' ],
        name     => 'checkout',
        pristine => 1,
        session  => undef,
        valid    => undef,
        values   => {},
      },
      "response looks good"
      or diag explain $data;
};

subtest 'post checkout no errors' => sub {
    $req = POST "$url/checkout", [ one => "foo", two => "bar" ];
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    ok $res->is_success, "POST /checkout successful";
    is exception { $data = decode_json( $res->content ) }, undef, "decode json";

    cmp_deeply $data,
      {
        action   => undef,
        errors   => {},
        fields   => [],
        name     => 'checkout',
        pristine => 0,
        session  => undef,
        valid    => undef,
        values   => { one => 'foo', two => 'bar' },
      },
      "response looks good"
      or diag explain $data;
};

subtest 'post checkout and add error writes to session' => sub {
    $req = POST "$url/checkout_add_error", [ one => "foo", two => "bar" ];
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    ok $res->is_success, "POST /checkout_add_error successful";
    is exception { $data = decode_json( $res->content ) }, undef, "decode json";

    cmp_deeply $data,
      {
        action => undef,
        errors => {
            one => 'looks dodgy',
        },
        fields   => [],
        name     => 'checkout',
        pristine => 0,
        session  => {
            checkout => {
                action => undef,
                errors => {
                    one => 'looks dodgy',
                },
                fields => [],
                name   => 'checkout',
                valid  => 0,
                values => {
                    one => 'foo',
                    two => 'bar',
                },
            },
        },
        valid  => 0,
        values => {
            one => 'foo',
            two => 'bar'
        },
      },
      "response looks good"
      or diag explain $data;
};

subtest 'get checkout should retrieve form from session' => sub {
    $req = GET "$url/checkout";
    $jar->add_cookie_header($req);
    $res = $test->request($req);
    ok $res->is_success, "GET /checkout successful";
    is exception { $data = decode_json( $res->content ) }, undef, "decode json";

    cmp_deeply $data,
      {
        action => '/checkout',
        errors => {
            one => 'looks dodgy',
        },
        fields   => ['one','two'],
        name     => 'checkout',
        pristine => 0,
        session  => {
            checkout => {
                action => undef,
                errors => {
                    one => 'looks dodgy',
                },
                fields => [],
                name   => 'checkout',
                valid  => 0,
                values => {
                    one => 'foo',
                    two => 'bar',
                },
            },
        },
        valid  => 0,
        values => {
            one => 'foo',
            two => 'bar'
        },
      },
      "response looks good"
      or diag explain $data;
};

done_testing;
