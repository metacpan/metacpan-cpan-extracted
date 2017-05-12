use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use Test::WWW::Mechanize::PSGI;
use Plack::Builder;

{
    package MyApp;
    use parent qw/Amon2/;

    sub load_config { +{} }

    __PACKAGE__->load_plugins(
        'L10N' => {
            default_lang          => '',
            accept_langs          => [qw/ ja th /],
            po_dir                => File::Spec->catfile(qw/ t po /),
            before_detection_hook => sub {
                my $c = shift;
                $c->req->param('before');
            },
            after_detection_hook  => sub {
                my($c, $lang) = @_;
                $c->req->param('after') || $lang;;
            },
        },
    );

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Encode;
    use File::Spec;

    sub dispatch {
        my $c = shift;
        $c->create_response(200, [], [ encode( utf8 => $c->loc('Hello, %1', 'yappo') ) ]);
    }
}

my $app = MyApp::Web->to_app;

subtest 'ja th' => sub {
    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/?before=ja',
                [],
            ));
            is $res->content, 'yappo さん、こんにちは';
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/?after=th',
                [],
            ));
            is $res->content, 'สวัสดีนาย yappo';
        }
    );
};


subtest 'default' => sub {
    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/?after=out',
                [],
            ));
            is $res->content, 'Hello, %1, yappo';
        }
    );
};


{
    package MyApp2;
    use parent qw/Amon2/;

    sub load_config { +{} }

    __PACKAGE__->load_plugins(
        'L10N' => {
            default_lang          => '',
            accept_langs          => [qw/ en /],
            po_dir                => File::Spec->catfile(qw/ t po /),
        },
    );

    package MyApp2::Web;
    use parent -norequire, qw/MyApp2/;
    use parent qw/Amon2::Web/;
    use Encode;
    use File::Spec;

    sub dispatch {
        my $c = shift;
        $c->create_response(200, [], [ encode( utf8 => $c->loc('Hello, %1', 'yappo') ) ]);
    }
}

my $app2 = MyApp2::Web->to_app;

subtest 'en' => sub {
    test_psgi(
        app    => $app2,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [],
            ));
            is $res->content, 'Hello yappo';
        }
    );
};

{
    package MyApp3;
    use parent qw/Amon2/;

    sub load_config { +{} }

    __PACKAGE__->load_plugins(
        'L10N' => {
            default_lang          => 'ja',
            accept_langs          => [qw/ ja /],
            po_dir                => File::Spec->catfile(qw/ t po /),
        },
    );

    package MyApp3::Web;
    use parent -norequire, qw/MyApp3/;
    use parent qw/Amon2::Web/;
    use Encode;
    use File::Spec;

    sub dispatch {
        my $c = shift;
        $c->create_response(200, [], [ encode( utf8 => $c->loc('Japan Hello, %1', 'yappo') ) ]);
    }
}

my $app3 = MyApp3::Web->to_app;

subtest 'ja' => sub {
    test_psgi(
        app    => $app3,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [],
            ));
            is $res->content, 'Japan Hello, yappo';
        }
    );
};

done_testing;
