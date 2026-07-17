use v5.36;
use Test::More;
use Test::Fatal;

my $role = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Role::Store';
require_ok($role);

# A class that consumes the Role but implements nothing fails composition,
# naming a missing required method.
{
    my $err = exception {
        package Bad::Store;
        use Moo;
        with 'Catalyst::Plugin::OAuth2::AuthorizationServer::Role::Store';
    };
    ok( $err, 'incomplete Store fails to compose' );
    like( $err, qr/create_client|missing|requires/i,
        'composition error names a required method' );
}

# A complete stub composes cleanly and DOES the role.
{
    my $ok = exception {
        package Good::Store;
        use Moo;
        with 'Catalyst::Plugin::OAuth2::AuthorizationServer::Role::Store';
        sub create_client { }
        sub find_client { }
        sub save_authorization_request { }
        sub take_authorization_request { }
        sub create_auth_code { }
        sub consume_auth_code { }
        sub create_refresh_token { }
        sub rotate_refresh_token { }
        sub revoke_family { }
        sub revoke_refresh_tokens_for_subject { }
    };
    is( $ok, undef, 'complete Store composes' );
    ok( Good::Store->new->DOES($role), 'DOES the Store role' );
}

# A Store missing only revoke_family fails to compose: reuse detection is
# useless without it, so the Role must demand it rather than let a host app
# discover the gap when an attacker replays a token.
{
    my $err = exception {
        package No::Family::Store;
        use Moo;
        with 'Catalyst::Plugin::OAuth2::AuthorizationServer::Role::Store';
        sub create_client { }
        sub find_client { }
        sub save_authorization_request { }
        sub take_authorization_request { }
        sub create_auth_code { }
        sub consume_auth_code { }
        sub create_refresh_token { }
        sub rotate_refresh_token { }
        sub revoke_refresh_tokens_for_subject { }
    };
    ok( $err, 'a Store without revoke_family fails to compose' );
    like( $err, qr/revoke_family/,
        'and the error names revoke_family' );
}

done_testing;
