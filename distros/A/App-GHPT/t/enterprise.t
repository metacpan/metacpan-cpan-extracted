#!perl
use strict;
use warnings;

# use lib 't/lib';

use App::GHPT::WorkSubmitter ();
use Test::More import => [qw( done_testing is ok )];
use Test::Differences qw( eq_or_diff );
use Test::Needs       qw( File::pushd Test::Git );

Test::Git->import('test_repository');
my $repo = test_repository();

$repo->run(
    'remote', 'add', 'origin',
    'git@github.example.com:del/trotter.git'
);

File::pushd->import('pushd');
my $dir = pushd( $repo->git_dir );

local $ENV{GITHUB_TOKEN}            = undef;
local $ENV{GH_TOKEN}                = undef;
local $ENV{GH_ENTERPRISE_TOKEN}     = undef;
local $ENV{GITHUB_ENTERPRISE_TOKEN} = undef;

{
    my $secret = 'ghenterprisesecret';
    local $ENV{GH_ENTERPRISE_TOKEN} = $secret;
    my $ws = App::GHPT::WorkSubmitter->new;
    is( $ws->_token_from_env, $secret,              'token' );
    is( $ws->_host,           'github.example.com', 'host found via remote' );
    ok( $ws->_is_ghe, 'is a ghe host' );

    eq_or_diff(
        $ws->_pithub_args,
        {
            api_uri => 'https://github.example.com/api/v3/',
            head    => 'HEAD',
            repo    => 'trotter',
            token   => $secret,
            user    => 'del',
        },
        'Pithub args'
    );
}

{
    my $secret = 'githubenterprisesecret';
    local $ENV{GITHUB_ENTERPRISE_TOKEN} = $secret;
    my $ws = App::GHPT::WorkSubmitter->new;
    is( $ws->_token_from_env, $secret, 'token' );
}

{
    my $secret = 'githubsecret';
    local $ENV{GITHUB_TOKEN} = $secret;
    my $ws = App::GHPT::WorkSubmitter->new;
    is( $ws->_token_from_env, $secret, 'token' );
}

{
    my $secret = 'ghsecret';
    local $ENV{GH_TOKEN} = $secret;
    my $ws = App::GHPT::WorkSubmitter->new;
    is(
        $ws->_token_from_env, undef,
        'no token from GH_TOKEN when URL is GHE'
    );
}

done_testing();
