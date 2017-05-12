#!perl

use lib qw(inc t/lib);

use Test::More;
use Catalyst::Model::MogileFS::Client;
use Test::Catalyst::Model::MogileFS::Client::Utils;

plan tests => 2;

SKIP: {
    my $utils;

    eval {
        $utils = Test::Catalyst::Model::MogileFS::Client::Utils->new;
    };
    if ($@) {
        skip( "Maybe not running mogilefsd, " . $@, 2 );
    }

    my $mogile = Catalyst::Model::MogileFS::Client->new({
        domain => $utils->domain,
        hosts => $utils->hosts
    });

    ok(UNIVERSAL::isa($mogile, 'Catalyst::Model::MogileFS::Client'), 'create Catalyst::Model::MogileFS::Client instance');
    ok(UNIVERSAL::isa($mogile->client, 'MogileFS::Client'), 'create MogileFS::Client instance');
}
