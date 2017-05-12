use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

use App::Nopaste::Service::Gist;

# clear these first to avoid interfering with tests -- and be sure we don't
# accidentally user's credentials into test results!
local $ENV{GITHUB_USER};
local $ENV{GITHUB_PASSWORD};
local $ENV{GITHUB_OAUTH_TOKEN};

ok(App::Nopaste::Service::Gist->available);
ok(!App::Nopaste::Service::Gist->forbid_in_default);

{
    local $ENV{GITHUB_OAUTH_TOKEN} = 'foo';
    cmp_deeply(
        [ App::Nopaste::Service::Gist->_get_auth() ],
        [ oauth_token => 'foo' ],
        'got OAuth token as credentials',
    );
}

{
    local $ENV{GITHUB_USER}     = 'perl';
    local $ENV{GITHUB_PASSWORD} = 'user';

    cmp_deeply(
        [ App::Nopaste::Service::Gist->_get_auth() ],
        [ username => 'perl', password => 'user' ],
        'got plaintext user, password as credentials',
    );
}

my $has_config_file = -f path('~', '.github');

SKIP:
{
    skip '~/.github exists; cannot test missing GITHUB_PASSWORD', 1 if $has_config_file;

    local $ENV{GITHUB_USER}     = 'perl';
    like(
        exception { App::Nopaste::Service::Gist->_get_auth() },
        qr/Export GITHUB_OAUTH_TOKEN first. For example:/,
        'User is warned that a GITHUB_OAUTH_TOKEN is required',
    );
}

SKIP:
{
    skip '~/.github exists; cannot test missing GITHUB_USER', 1 if $has_config_file;

    local $ENV{GITHUB_PASSWORD} = 'user';
    like(
        exception { App::Nopaste::Service::Gist->_get_auth() },
        qr/Export GITHUB_OAUTH_TOKEN first. For example:/,
        'User is warned that a GITHUB_OAUTH_TOKEN is required',
    );
}

done_testing;
