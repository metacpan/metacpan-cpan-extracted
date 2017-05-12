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
            accept_langs => [qw/ en ja /],
            po_dir       => File::Spec->catfile(qw/ t po /),
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

subtest 'en' => sub {
    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [ 'Accept-Language', 'en' ],
            ));
            is $res->content, 'Hello, yappo';
        }
    );
};

subtest 'ja' => sub {
    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [ 'Accept-Language', 'en;q=0.1, ja;q=0.12' ],
            ));
            is $res->content, 'yappo さん、こんにちは';
        }
    );
};


subtest 'default' => sub {
    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [ 'Accept-Language', 'th' ],
            ));
            is $res->content, 'Hello, yappo';
        }
    );
};

done_testing;
