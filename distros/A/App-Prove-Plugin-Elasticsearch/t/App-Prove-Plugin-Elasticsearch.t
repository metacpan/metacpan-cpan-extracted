use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use FindBin;
use App::Prove;
use App::Prove::Plugin::Elasticsearch;

MAIN: {

    my $straightdope = { 'server.host' => 'zippy.test', 'server.port' => 666 };

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Indexer::check_index = sub { };
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return $straightdope };
    local *App::Prove::Elasticsearch::Utils::require_indexer = sub { return 'App::Prove::Elasticsearch::Indexer' };
    use warnings;

    my $p = {args => [], app_prove => App::Prove->new()};
    is(exception { App::Prove::Plugin::Elasticsearch->load($p) }, undef, "Happy path can execute all the way through");

    $straightdope = {};
    my $out = '';
    is(exception { $out = capture_merged { App::Prove::Plugin::Elasticsearch->load($p) } }, undef, "Zero-Conf path can execute all the way through");
    like($out,qr/insufficient information/i,"Zero-conf run skips upload");
}

