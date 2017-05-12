use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

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
        if ($c->request->path_info =~ m!^/ua_is_pc$!) {
            return $c->create_response(
                200,
                [],
                [ $c->ua_is_pc ],
            );
        }
        elsif ($c->request->path_info =~ m!^/ua_is_crawler$!) {
            return $c->create_response(
                200,
                [],
                [ $c->ua_is_crawler ],
            );
        }
        elsif ($c->request->path_info =~ m!^/ua_is_smartphone$!) {
            return $c->create_response(
                200,
                [],
                [ $c->ua_is_smartphone ],
            );
        }
        elsif ($c->request->path_info =~ m!^/ua_is_mobilephone$!) {
            return $c->create_response(
                200,
                [],
                [ $c->ua_is_mobilephone ],
            );
        }
        elsif ($c->request->path_info =~ m!^/ua_is_misc$!) {
            return $c->create_response(
                200,
                [],
                [ $c->ua_is_misc ],
            );
        }
        elsif ($c->request->path_info =~ m!^/woothee$!) {
            return $c->create_response(
                200,
                [],
                [ $c->woothee->name ],
            );
        }
        return $c->create_response(404, [], []);
    }
    __PACKAGE__->load_plugins('Web::Woothee');
}

my $agent = {
    MSIE => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)',
    googlebot => join(' ',
        'Mozilla/5.0',
        '(compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
    ),
    iPhone => join(' ',
        'Mozilla/5.0',
        '(iPhone; CPU iPhone OS 5_0_1 like Mac OS X)',
        'AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1',
        'Mobile/9A405 Safari/7534.48.3',
    ),
    docomo => 'DoCoMo/2.0 SH01A(c100;TB;W24H16)',
    RSSReader => 'AppleSyndication/56.1',
};

my $mech = Test::WWW::Mechanize::PSGI->new(app => MyApp::Web->to_app);

{
    $mech->agent($agent->{googlebot});
    $mech->get_ok('/ua_is_pc');
    $mech->content_contains(0);

    $mech->agent($agent->{MSIE});
    $mech->get_ok('/ua_is_pc');
    $mech->content_contains(1);
}

{
    $mech->agent($agent->{MSIE});
    $mech->get_ok('/ua_is_crawler');
    $mech->content_contains(0);

    $mech->agent($agent->{googlebot});
    $mech->get_ok('/ua_is_crawler');
    $mech->content_contains(1);
}

{
    $mech->agent($agent->{MSIE});
    $mech->get_ok('/ua_is_smartphone');
    $mech->content_contains(0);

    $mech->agent($agent->{iPhone});
    $mech->get_ok('/ua_is_smartphone');
    $mech->content_contains(1);
}

{
    $mech->agent($agent->{MSIE});
    $mech->get_ok('/ua_is_mobilephone');
    $mech->content_contains(0);

    $mech->agent($agent->{docomo});
    $mech->get_ok('/ua_is_mobilephone');
    $mech->content_contains(1);
}

{
    $mech->agent($agent->{MSIE});
    $mech->get_ok('/ua_is_misc');
    $mech->content_contains(0);

    $mech->agent($agent->{RSSReader});
    $mech->get_ok('/ua_is_misc');
    $mech->content_contains(1);
}

{
    $mech->agent($agent->{MSIE});
    $mech->get_ok('/woothee');
    $mech->content_contains('Internet Explorer');
}

done_testing;
