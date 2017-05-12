use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use Test::WWW::Mechanize::PSGI;
use Plack::Builder;

{
    package L10N;
    use strict;
    use warnings;
    use parent 'Locale::Maketext';
    use File::Spec;

    use Locale::Maketext::Lexicon +{
        'ja'     => [ Gettext => File::Spec->catfile('t', 'po', 'ja.po') ],
        _preload => 1,
        _style   => 'gettext',
        _decode  => 1,
    };

    package MyApp;
    use parent qw/Amon2/;

    sub load_config { +{} }

    __PACKAGE__->load_plugins(
        'L10N' => {
            accept_langs => [qw/ ja /],
            po_dir       => File::Spec->catfile(qw/ foo bar baz /),
            l10n_class   => 'L10N',
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

subtest 'ja' => sub {
    test_psgi(
        app    => $app,
        client => sub {
            my $cb = shift;
            my $res = $cb->(HTTP::Request->new(
                GET => 'http://localhost/',
                [ 'Accept-Language', 'ja' ],
            ));
            is $res->content, 'yappo さん、こんにちは';
        }
    );
};

done_testing;
