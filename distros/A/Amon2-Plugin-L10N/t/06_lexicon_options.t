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
            accept_langs         => [qw/ en ja th /],
            po_dir               => File::Spec->catfile(qw/ t po /),
        },
    );

    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    use Encode;
    use File::Spec;

    sub dispatch {
        my $c = shift;
        $c->create_response(200, [], [ encode( utf8 => $c->loc('good') ) ]);
    }
}

my $app = MyApp::Web->to_app;

subtest 'good' => sub {
    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [ 'Accept-Language', 'ja' ],
            ));
            is $res->content, 'good';
        }
    );
};


{
    package MyApp2;
    use parent qw/Amon2/;

    sub load_config { +{} }

    __PACKAGE__->load_plugins(
        'L10N' => {
            accept_langs         => [qw/ en ja th /],
            po_dir               => File::Spec->catfile(qw/ t po /),
            lexicon_options      => {
                _auto => 0,
            },
        },
    );

    package MyApp2::Web;
    use parent -norequire, qw/MyApp2/;
    use parent qw/Amon2::Web/;
    use Encode;
    use File::Spec;

    sub dispatch {
        my $c = shift;
        $c->create_response(200, [], [ encode( utf8 => $c->loc('bad exception') ) ]);
    }
}

my $app2 = MyApp2::Web->to_app;

subtest 'bad' => sub {
    test_psgi(
        app    => $app2,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [ 'Accept-Language', 'ja' ],
            ));
            like $res->content, qr/bad exception/;
        }
    );
};

done_testing;
