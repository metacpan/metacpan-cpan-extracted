use strict;

use File::Basename;
use Path::Tiny;
use FindBin qw( $Bin );
use HTTP::Request::Common;
use JSON::MaybeXS;
use Module::Load;
use Plack::Test;
use Test::More;
use Test::Mock::LWP::Dispatch;
use URI;

# setup LWP mocking
my %http_responses;
for my $file (glob("$Bin/responses/*")) {
    $http_responses{basename($file)} = path($file)->slurp;
}
$mock_ua->map(qr{^https://graph.facebook.com/oauth/access_token}, HTTP::Response->parse($http_responses{'facebook-access_token'}));
$mock_ua->map(qr{^https://graph.facebook.com/me},                 HTTP::Response->parse($http_responses{'facebook-user_info'}));

$mock_ua->map(qr{^https://accounts.google.com/o/oauth2/token},    HTTP::Response->parse($http_responses{'google-access_token'}));
$mock_ua->map(qr{^https://www.googleapis.com/oauth2/v2/userinfo}, HTTP::Response->parse($http_responses{'google-user_info'}));

$mock_ua->map(qr{^https://twitter.com/oauth/request_token},       HTTP::Response->parse($http_responses{'twitter-request_token'}));
$mock_ua->map(qr{^https://twitter.com/oauth/access_token},        HTTP::Response->parse($http_responses{'twitter-access_token'}));
$mock_ua->map(qr{^https://api.twitter.com/1.1/account/verify},    HTTP::Response->parse($http_responses{'twitter-user_info'}));

$mock_ua->map(qr{^https://github.com/login/oauth/access_token},   HTTP::Response->parse($http_responses{'github-access_token'}));
$mock_ua->map(qr{^https://api.github.com/user},                   HTTP::Response->parse($http_responses{'github-user_info'}));

$mock_ua->map(qr{^https://stackexchange.com/oauth/access_token},  HTTP::Response->parse($http_responses{'stackexchange-access_token'}));
$mock_ua->map(qr{^https://api.stackexchange.com/2.2/me},          HTTP::Response->parse($http_responses{'stackexchange-user_info'}));

$mock_ua->map(qr{^https://www.linkedin.com/oauth/v2/accessToken}, HTTP::Response->parse($http_responses{'linkedin-access_token'}));
$mock_ua->map(qr{^https://api.linkedin.com/v1/people/.*},         HTTP::Response->parse($http_responses{'linkedin-user_info'}));


# setup dancer app
{
    package App;
    use Dancer2;
    use Dancer2::Plugin::Auth::OAuth;

    get '/dump_session' => sub {
        content_type 'application/json';
        return to_json session('oauth');
    };

    true;
}

# setup plack
my $app = App->psgi_app;
is( ref $app, 'CODE', 'Got app' );

test_psgi
    app    => $app,
    client => sub {
        my $cb  = shift;

        for my $provider (qw(facebook google twitter github stackexchange linkedin)) {
            ### setup
            my $provider_module = "Dancer2::Plugin::Auth::OAuth::Provider::".ucfirst($provider);
            load $provider_module;
            my $p = $provider_module->new;

            my %wanted_q = (
                twitter => {
                    oauth_callback => "http://localhost/auth_test/$provider/callback",
                    oauth_token => 'some_dummy_token',
                },
                facebook => {
                    response_type=> 'code',
                    scope        => 'email,public_profile,user_friends',
                    client_id    => 'some_client_id',
                    redirect_uri => "http://localhost/auth_test/$provider/callback",
                },
                google => {
                    response_type=> 'code',
                    scope        => 'openid email',
                    client_id    => 'some_client_id',
                    redirect_uri => "http://localhost/auth_test/$provider/callback",
                },
                github => {
                    redirect_uri => "http://localhost/auth_test/$provider/callback",
                    client_id    => 'some_client_id',
                },
                stackexchange => {
                    redirect_uri => "http://localhost/auth_test/$provider/callback",
                    client_id    => 'some_client_id',
                },
                linkedin => {
                    redirect_uri => "http://localhost/auth_test/$provider/callback",
                    client_id    => 'some_client_id',
                    response_type=> 'code',
                },
            );
            my $wanted_uri = URI->new( $provider_module->config->{urls}{authorize_url} );
               $wanted_uri->query_form( $wanted_q{$provider} );

            ### login
            my $res = $cb->(GET "/auth_test/$provider");
            is($res->code, 302, "[$provider] Response code (302)");

            my $got_uri = URI->new($res->header('Location'));
            for ( qw(scheme host path) ) {
                ok($got_uri->$_ eq $wanted_uri->$_, "[$provider] Redirect URL ($_)");
            }

            is_deeply( +{ $got_uri->query_form }, +{ $wanted_uri->query_form }, "[$provider] Redirect URL (query)" );

            ### callback
            $res = $cb->(GET "/auth_test/$provider/callback?oauth_token=foo&oauth_verifier=bar&code=foobar"); # mixing oauth versions
            ok($res->code == 302, "[$provider][cb] Response code (302)");
            is($res->header('Location'), 'http://localhost/users', "[$provider] success_url setting");

            my $cookie = $res->header('Set-Cookie');
               $cookie =~ s/;.*$//;
            ok($cookie =~ m/^dancer.session=/, "[$provider] Cookie");

            ### session dump
            my %wanted_session = (
                'twitter' => {
                    'access_token_secret' => 'some_dummy_s3kret',
                    'access_token' => 'some_dummy_token',
                    'extra' => { 'user_id' => '666', 'screen_name' => 'b10m' },
                    'user_info' => {
                        'id' => 666, 'id_str' => '666', name => 'Menno Blom',
                        'screen_name' => 'B10m', 'location' => 'Amsterdam'
                    }
                },
                'facebook' => {
                    'expires' => 666, 'access_token' => 'accesstoken',
                    'user_info' => {
                        'email' => 'blom\\u0040cpan.org', 'first_name' => 'Menno',
                        'id' => '666', 'last_name' => 'Blom',
                        'link' => 'https:\\/\\/image', 'locale' => 'en_US',
                        'name' => 'Menno Blom', 'timezone' => 2,
                        'updated_time' => '1970-01-01T00:00:00+0000',
                        'verified' => '1'
                    }
                },
                'google' => {
                    'id_token' => 'id_token', 'token_type' => 'Bearer',
                    'expires_in' => 3600, 'access_token' => 'accesstoken',
                    'user_info' => {
                         'family_name' => 'Blom', 'id' => '666', 'verified_email' => 1,
                         'link' => 'https://plus.google.com/666', 'gender' => 'male',
                         'picture' => 'https://image', 'email' => 'blom@cpan.org',
                         'name' => 'Menno Blom', 'given_name' => 'Menno'
                     }
                },
                github => {
                    access_token => 'jhj5j4j44jh29dn',
                    token_type => 'bearer',
                    scope => 'user,gist',
                    user_info => {
                        login => "octocat",
                        id => 1,
                        avatar_url => "https://github.com/images/error/octocat_happy.gif",
                        gravatar_id => "",
                        url => "https://api.github.com/users/octocat",
                        html_url => "https://github.com/octocat",
                        followers_url => "https://api.github.com/users/octocat/followers",
                        subscriptions_url => "https://api.github.com/users/octocat/subscriptions",
                        organizations_url => "https://api.github.com/users/octocat/orgs",
                        repos_url => "https://api.github.com/users/octocat/repos",
                        received_events_url => "https://api.github.com/users/octocat/received_events",
                        type => "User",
                        site_admin => 0,
                        name => "monalisa octocat",
                        company => "GitHub",
                        blog => "https://github.com/blog",
                        location => "San Francisco",
                        email => 'octocat@github.com',
                        hireable => 0,
                        bio => "There once was...",
                        public_repos => 2,
                        public_gists => 1,
                        followers => 20,
                        following => 0,
                        created_at => "2008-01-14T04:33:35Z",
                        updated_at => "2008-01-14T04:33:35Z",
                        total_private_repos => 100,
                        owned_private_repos => 100,
                        private_gists => 81,
                        disk_usage => 10000,
                        collaborators => 8,
                        plan => {
                            name => "Medium",
                            space => 400,
                            private_repos => 20,
                            collaborators => 0
                        },
                    },
                },
                stackexchange => {
                    access_token => '9813893ejsndsn93783',
                    expires => 1234,
                    user_info => {
                        has_more => 0,
                        quota_max => 10000,
                        quota_remaining => 9998,
                        items => [{
                            badge_counts => {
                                bronze => 8,
                                silver => 1,
                                gold => 0,
                            },
                            last_modified_date => 1337656466,
                            last_access_date => 1449843597,
                            age => 30,
                            reputation_change_year => 39,
                            reputation_change_quarter => -1,
                            reputation_change_month => 0,
                            reputation_change_week => 0,
                            reputation_change_day => 0,
                            reputation => 157,
                            creation_date => 1313242661,
                            user_type => "registered",
                            location => "Sydney, Australia",
                        }],
                    },
                },
                linkedin => {
                    access_token => 'accesstoken',
                    expires_in => 5184000,
                    user_info => {
                        pictureUrl => 'https://media.licdn.com/mpr/mprx/hash',
                        formattedName => 'Menno Blom',
                        emailAddress => 'blom@cpan.org',
                        id => 'someStr1ng',
                    }
                },
            );
            $res = $cb->(GET "/dump_session", ( Cookie => $cookie ));
            my $session = decode_json( $res->content );
            is_deeply( $session->{$provider}, $wanted_session{$provider}, "[$provider] Session data");
        }

    };

# all done!
done_testing;
