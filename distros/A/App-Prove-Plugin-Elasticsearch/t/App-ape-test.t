use strict;
use warnings;

package Test::GrapeApe::Tester;

use parent qw{Test::Class};
use Test::More;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture};

use App::ape::test;

sub test_new : Test(4) {
    is(App::ape::test->new(),1,"Passing no args results in error");
    is(App::ape::test->new(qw{--status OK}),2,"Passing no tests results in error");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return {} };
    use warnings;

    is(App::ape::test->new(qw{--status OK whee.test}),3,"Calling with insufficient configuration results in error");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub { return { 'server.host' => 'whee.test', 'server.port' => 666 } };
    local *App::Prove::Elasticsearch::Utils::require_indexer    = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_versioner  = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_blamer     = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_searcher   = sub { return "Grape::Ape" };
    local *App::Prove::Elasticsearch::Utils::require_platformer = sub { return "Grape::Ape" };
    local *Grape::Ape::check_index = sub {};
    local *Grape::Ape::new = sub { return bless({},'Grape::Ape') };
    local *Grape::Ape::get_version = sub { return 666 };
    local *Grape::Ape::get_file_version = sub { return 8675309 };
    local *Grape::Ape::get_platforms = sub { return ['a','b'] };
    use warnings;

    isa_ok(App::ape::test->new(qw{--status OK whee.test}),"App::ape::test");
}

sub test_run: Test(1) {
    my $obj = bless({
        'cases' => [
            { name => 'a', version => 666 },
            { name => 'b', version => 666 }
        ],
        blamer => 'Grape::Ape',
        indexer => 'Grape::Ape',
        options => { status => 'whee' },
        platforms => [],
        version => 666,
    }, "App::ape::test");

    no warnings qw{redefine once};
    local *Grape::Ape::get_repsonsible_party = sub { return 'billy' };
    local *App::ape::test::get_test_commentary = sub {return "i tell you what" };
    local *Grape::Ape::index_results = sub {};
    use warnings;

    is($obj->run(),0,"run() can go all the way thru");
}

#I'm not testing get_test_commentary for now.

__PACKAGE__->runtests();
