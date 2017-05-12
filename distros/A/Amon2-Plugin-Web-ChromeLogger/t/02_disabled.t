use strict;
use warnings;
use Test::More;
use Test::WWW::Mechanize::PSGI;

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
        if ($c->request->path_info =~ m!^/disabled$!) {
            eval { $c->chrome_logger->info('aloha!'); };
            return $c->create_response(
                200,
                [],
                [$@],
            );
        }
        return $c->create_response(404, [], []);
    }
    __PACKAGE__->load_plugins('Web::ChromeLogger' => { disabled => 1 });
}

my $mech = Test::WWW::Mechanize::PSGI->new(app => MyApp::Web->to_app);

{
    $mech->get_ok('/disabled');
    $mech->content_contains(qq|Can't locate object method "chrome_logger"|);
    is $mech->res->header('X-ChromeLogger-Data'), undef;
}

done_testing;
