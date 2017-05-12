use strict;
use warnings;
use Test::More;
use Test::WWW::Mechanize::PSGI;
use MIME::Base64;
use JSON::XS;

local $ENV{PLACK_ENV} = 'production';

{
    package MyApp;
    use parent qw/Amon2/;
}

{
    package MyApp::Web;
    use parent -norequire, qw/MyApp/;
    use parent qw/Amon2::Web/;
    sub dispatch {
        my $c = shift;
        if ($c->request->path_info =~ m!^/production$!) {
            eval { $c->chrome_logger->info('aloha!'); };
            return $c->create_response(
                200,
                [],
                [$@],
            );
        }
        return $c->create_response(404, [], []);
    }
    # PLACK_ENV: 'production', and this plugin is disabled.
    __PACKAGE__->load_plugins('Web::ChromeLogger');
}

my $mech = Test::WWW::Mechanize::PSGI->new(app => MyApp::Web->to_app);

{
    $mech->get_ok('/production');
    $mech->content_contains(qq|Can't locate object method "chrome_logger"|);
    is $mech->res->header('X-ChromeLogger-Data'), undef;
}


{
    package MyApp2;
    use parent qw/Amon2/;
}

{
    package MyApp2::Web;
    use parent -norequire, qw/MyApp2/;
    use parent qw/Amon2::Web/;
    sub dispatch {
        my $c = shift;
        if ($c->request->path_info =~ m!^/production$!) {
            $c->chrome_logger->info('aloha!');
            return $c->create_response(
                200,
                [],
                ['aloha'],
            );
        }
        return $c->create_response(404, [], []);
    }
    # PLACK_ENV: 'production', but this plugin is enabled with enable_in_production option.
    __PACKAGE__->load_plugins('Web::ChromeLogger' => { enable_in_production => 1 });
}

my $mech2 = Test::WWW::Mechanize::PSGI->new(app => MyApp2::Web->to_app);

{
    $mech2->get_ok('/production');
    $mech2->content_contains('aloha');
    my $chrome_log = $mech2->res->header('X-ChromeLogger-Data');
    my $json = MIME::Base64::decode_base64($chrome_log);
    my $dat = decode_json($json);
    is $dat->{rows}[0][0][0], 'aloha!';
}

done_testing;
