package DBICTest;

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;
use Dancer2::Plugin::Auth::Extensible::Test;

my $jar = HTTP::Cookies->new();

sub runtests {
    my $test = Plack::Test->create(shift);

    *get  = \&Dancer2::Plugin::Auth::Extensible::Test::get;
    *post = \&Dancer2::Plugin::Auth::Extensible::Test::post;

    subtest "DBIC provider-specific tests" => sub {
        my $res;

        for my $realm (qw/config1 config2/) {

            # check user is not yet logged in
 
            ok get('/loggedin')->is_redirect,
              "Make sure user in realm $realm is not yet logged in";

            #login

            $res = post(
                '/login',
                [
                    username => 'mark',
                    password => "wantscider",
                    realm    => $realm,
                ]
            );

            ok $res->is_redirect, "/login looks good";

            is get('/loggedin')->content, "You are logged in",
              "... and checking /loggedin route shows we are logged in";

            # First check that the role doesn't work.

            $res = get('/dbic_cider');
            is $res->code, 403, "We cannot yet access CiderDrinker route"
              or diag explain $res;

            # add role

            $res = get("/dbic_update_user_role/$realm");
            ok $res->is_success, "get /dbic_update_user_role/$realm is_success"
              or diag explain $res;

            # check route again

            $res = get('/dbic_cider');
            ok $res->is_success, "We *can* now access CiderDrinker route";
            is $res->content, "You can have a cider",
              "... and we see the page content.";

            # cleanup
            $res = post('/logout');
        }
    };
}

1;
