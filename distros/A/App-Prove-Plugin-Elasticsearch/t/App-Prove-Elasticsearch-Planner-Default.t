use strict;
use warnings;

use Test::More tests => 29;
use Test::Deep;
use Test::Fatal;
use Capture::Tiny qw{capture_merged};

use App::Prove::Elasticsearch::Planner::Default;

INDEXER: {
    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return bless({},'Search::Elasticsearch') };
    local *Search::Elasticsearch::indices = sub { return bless({},'Search::Elasticsearch::Indices') };
    local *Search::Elasticsearch::Indices::exists = sub { return 1};
    use warnings;

    like(exception { App::Prove::Elasticsearch::Planner::Default::check_index() }, qr/server must be specified/i,"Indexer dies in the event server & port  is not specified");
    like(exception { App::Prove::Elasticsearch::Planner::Default::check_index({ 'server.port' => 666 }) }, qr/server must be specified/i,"Indexer dies in the event server are not specified");
    like(exception { App::Prove::Elasticsearch::Planner::Default::check_index({ 'server.host' =>'zippy.test' }) }, qr/port must be specified/i,"Indexer dies in the event port is not specified");

    is(App::Prove::Elasticsearch::Planner::Default::check_index({ 'server.host' => 'zippy.test', 'server.port' => 666}),0,"Indexer skips indexing in the event index already exists.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::Indices::exists = sub { return 0 };
    local *Search::Elasticsearch::Indices::create = sub { };
    use warnings;

    is(App::Prove::Elasticsearch::Planner::Default::check_index({ 'server.host' => 'zippy.test', 'server.port' => 666 }),1,"Indexer runs in the event index nonexistant.");
}

GET_PLAN: {
    #options: version must be set, platforms and name must be tested independently

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return undef };
    use warnings;
    $App::Prove::Elasticsearch::Planner::Default::e = bless({},'Search::Elasticsearch');

    #check version must be set
    like(exception { App::Prove::Elasticsearch::Planner::Default::get_plan()}, qr/version/ , "Not passing version fails to get plan");
    is(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666), 0, "get_plan: Bogus return from Search::Elasticsearch->search() returns false");


    my $ret = { hits => { hits => [] } };

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return $ret };
    use warnings;
    is(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666), 0, "get_plan: Empty return from Search::Elasticsearch->search() returns false");

    #check version alone may be passed
    $ret->{hits}{hits} = [
        {
            _source => {
                platforms => 'shoes',
                name      => 'zippyPlan',
                version   => 666,
                id        => 420,
            },
            _id => 420,
        }
    ];
    is_deeply(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666), $ret->{hits}{hits}->[0]->{_source}, "get_plan returns first matching plan ");

    #check name + version works
    is_deeply(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666, name => 'zippyPlan'), $ret->{hits}{hits}->[0]->{_source}, "get_plan returns first name matching plan ");
    is(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666, name => 'bogusPlan'), 0, "get_plan returns no plan when bogus name match returned");

    #check platforms + version works
    is_deeply(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666, platforms => ['shoes'] ), $ret->{hits}{hits}->[0]->{_source}, "get_plan returns first platform matching plan ");
    is(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666, platforms => ['socks'] ), 0, "get_plan returns no plan when bogus platform match returned");
    is(App::Prove::Elasticsearch::Planner::Default::get_plan(version => 666, platforms => ['socks','shoes'] ), 0, "get_plan returns no plan when insufficient platform match returned");

}

ADD_TO_INDEX: {
    is(App::Prove::Elasticsearch::Planner::Default::add_plan_to_index({ noop => 1 }),0,"add_plan_to_index skips NOOP plans");
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Planner::Default::_update_plan = sub { return 'whee' };
    use warnings;
    is(App::Prove::Elasticsearch::Planner::Default::add_plan_to_index({ update => 1 }),'whee',"add_plan_to_index punts to _update_plan on update plans");

    $App::Prove::Elasticsearch::Planner::Default::e = undef;
    like(exception {App::Prove::Elasticsearch::Planner::Default::add_plan_to_index()}, qr/es object not defined/i, "add_plan_to_index requires check_index be run first");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return undef };
    local *Search::Elasticsearch::index = sub { return 0 };
    local *Search::Elasticsearch::exists = sub { return 0 };
    local *App::Prove::Elasticsearch::Utils::get_last_index = sub { return 0 };
    use warnings;
    $App::Prove::Elasticsearch::Planner::Default::e = bless( {} , "Search::Elasticsearch");
    is(App::Prove::Elasticsearch::Planner::Default::add_plan_to_index(), 1, "add_plan_to_index returns 1 in the event of failure");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::exists = sub { return 1 };
    use warnings;
    is(App::Prove::Elasticsearch::Planner::Default::add_plan_to_index(), 0, "add_plan_to_index returns 0 in the event of success");

}

UPDATE_PLAN: {
    no warnings qw{redefine once};
    local *Search::Elasticsearch::update = sub {
        shift;
        my %in = @_;

        foreach my $test ( @{$in{body}{doc}{tests}} ) {
            print "$test ";
        }
        print "#\n";
        return { result => 'sadness came to us' };
    };
    use warnings;
    $App::Prove::Elasticsearch::Planner::Default::e = bless( {} , "Search::Elasticsearch");

    my $plan = {
        update => {
            addition => {
                tests => [
                    'zippy.test'
                ]
            },
            subtraction => {
                tests => [
                    'happy.test'
                ]
            },
        },
        tests => [ 'happy.test','chompy.test' ],
        id => 666,
    };
    my $res;
    my $out = capture_merged { $res = App::Prove::Elasticsearch::Planner::Default::_update_plan($plan) };
    is($res,1,"_update_plan returns 1 on failure");
    like($out,qr/^chompy.test zippy.test #/i,"Correct tests sent to update");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::update = sub {
        return { result => 'noop' };
    };
    use warnings;
    is(App::Prove::Elasticsearch::Planner::Default::_update_plan($plan),0,"_update_plan returns 0 on success");
}

MAKE_PLAN: {
    $App::Prove::Elasticsearch::Planner::Default::e = undef;
    like(exception {App::Prove::Elasticsearch::Planner::Default::make_plan()}, qr/es object not defined/i, "make_plan requires check_index be run first");
    $App::Prove::Elasticsearch::Planner::Default::e = bless( {} , "Search::Elasticsearch");

    my %out = (
        pairwise => 1,
        show => 1,
        prompt => 1,
        allplatforms => 1,
        exts => 1,
        recurse => 1,
        name => undef,
        tests => ['zippy'],
    );

    my $expected = {
        pairwise => 'true',
        tests    => ['zippy'],
    };

    is_deeply(App::Prove::Elasticsearch::Planner::Default::make_plan(%out),$expected,"make_plan sanitizes: no name, pairwise => true & noop => 0");

    $out{pairwise} = 0;
    $expected->{pairwise} = 'false';
    $out{tests} = [];
    $expected->{tests} = [];
    $expected->{noop} = 1;
    $out{name} = 'eee';
    $expected->{name} = 'eee';

    is_deeply(App::Prove::Elasticsearch::Planner::Default::make_plan(%out),$expected,"make_plan sanitizes: name, pairwise => false & noop => 1");

}

MAKE_PLAN_UPDATE: {
    $App::Prove::Elasticsearch::Planner::Default::e = undef;
    like(exception {App::Prove::Elasticsearch::Planner::Default::make_plan_update()}, qr/es object not defined/i, "make_plan_update requires check_index be run first");
    $App::Prove::Elasticsearch::Planner::Default::e = bless( {} , "Search::Elasticsearch");

    my $existing = {
        tests     => ['hoosafudge'],
    };

    my %out = (
        tests => ['zippy'],
    );

    my $expected = {
        tests    => ['hoosafudge'],
        update   => {
            addition    => { tests => ['zippy'] },
            subtraction => { tests => ['hoosafudge'] },
        }
    };

    is_deeply(App::Prove::Elasticsearch::Planner::Default::make_plan_update($existing,%out),$expected,"make_plan_update mongles: test add & sub & noop => 0");

    $out{tests}        = ['zippy'];
    $existing->{tests} = ['zippy'];
    $expected->{tests} = ['zippy'];
    delete $existing->{update};
    delete $expected->{update};
    $expected->{noop} = 1;

    is_deeply(App::Prove::Elasticsearch::Planner::Default::make_plan_update($existing,%out),$expected,"make_plan_update mongles: noop => 1");

}

GET_PLAN_STATUS: {
    my $plan = {
        version => 666,
        platforms => ['zippy'],
        tests => ['a','b',],
    };
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Searcher::ByName::get_test_replay = sub {return 'jello'};
    use warnings;
    my $searcher = bless({},'App::Prove::Elasticsearch::Searcher::ByName');

    is(App::Prove::Elasticsearch::Planner::Default::get_plan_status($plan,$searcher),'jello',"get_plan_status passthru to searcher get test replay works");
}
