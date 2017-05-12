use strict;
use warnings;
use Test::More;
use Test::WWW::Mechanize::PSGI;
use MIME::Base64;
use JSON;

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
        if ($c->request->path_info =~ m!^/json_encoder$!) {
            $c->chrome_logger->info('aloha!');
            return $c->create_response(
                200,
                [],
                ['aloha'],
            );
        }
        return $c->create_response(404, [], []);
    }
    __PACKAGE__->load_plugins('Web::ChromeLogger' => {
        json_encoder => JSON->new->ascii(1)->convert_blessed,
    });
}

my $mech = Test::WWW::Mechanize::PSGI->new(app => MyApp::Web->to_app);

{
    $mech->get_ok('/json_encoder');
    $mech->content_contains('aloha');
    my $chrome_log = $mech->res->header('X-ChromeLogger-Data');
    my $json = MIME::Base64::decode_base64($chrome_log);
    my $dat = decode_json($json);
    is $dat->{rows}[0][0][0], 'aloha!';
}

done_testing;
