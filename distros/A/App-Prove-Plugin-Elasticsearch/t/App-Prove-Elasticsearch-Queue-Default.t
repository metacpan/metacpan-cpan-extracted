use strict;
use warnings;

use Test::More tests => 12;
use Test::Fatal;
use Test::Deep;
use App::Prove::Elasticsearch::Queue::Default;
use Capture::Tiny qw{capture_merged};

is(App::Prove::Elasticsearch::Queue::Default::queue_jobs(),0,"q-jobs is no-op on default");

{
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration   = sub { return shift };
    local *App::Prove::Elasticsearch::Utils::require_planner         = sub { return 'App::Prove::Elasticsearch::Planner::Default' };
    local *App::Prove::Elasticsearch::Planner::Default::check_index  = sub {};
    use warnings;

    is( exception { App::Prove::Elasticsearch::Queue::Default->new({}) }, undef, "Constructor non-fatal on innocuous data");
}

{
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Queue::Default::_get_searcher   = sub { return shift->{'searcher'} = 'App::Prove::Elasticsearch::Searcher::ByName' };
    local *App::Prove::Elasticsearch::Planner::Default::get_plans_needing_work = sub { return [] };
    use warnings;

    my $obj = bless({
        planner => 'App::Prove::Elasticsearch::Planner::Default',
        config => { 'queue.granularity' => 2 },
    }, 'App::Prove::Elasticsearch::Queue::Default' );

    my @jobs = $obj->get_jobs({});
    is(scalar(@jobs),0,"No jobs returned when the planner can find nothing to do.");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Planner::Default::get_plans_needing_work = sub { return [{ tests => ['a.t','b.t','c.t'] }, { tests => ['e.t']} ] };
    local *App::Prove::Elasticsearch::Searcher::ByName::filter = sub { shift; return @_ };
    use warnings;

    @jobs = $obj->get_jobs({});
    is(scalar(@jobs) ,2, "2 jobs returned when granularity at 2") or diag explain \@jobs;

    $obj->{config}->{'queue.granularity'} = 0;
    @jobs = $obj->get_jobs({});
    is(scalar(@jobs) ,4, "all jobs returned when granularity not set or false") or diag explain \@jobs;

}

{
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::require_indexer = sub { return 'zippy' };
    use warnings;
    my $obj = bless({},'App::Prove::Elasticsearch::Queue::Default');
    is($obj->_get_indexer(), 'zippy', "get_indexer behaves as expected");
    is($obj->_get_indexer(), 'zippy', "get_indexer behaves as expected: cached");
}

{
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::require_searcher      = sub { return 'App::Prove::Elasticsearch::Searcher::ByName' };
    local *App::Prove::Elasticsearch::Queue::Default::_get_indexer = sub { return shift->{'indexer'} = 'App::Prove::Elasticsearch::Indexer' };
    local *App::Prove::Elasticsearch::Searcher::ByName::new        = sub { return 'zippy' };
    use warnings;
    my $obj = bless({},'App::Prove::Elasticsearch::Queue::Default');
    is($obj->_get_searcher(), 'zippy', "get_searcher behaves as expected");
    is($obj->_get_searcher(), 'zippy', "get_searcher behaves as expected: cached");
}

{
    no warnings qw{redefine once};
    my $delay = 0;
    local *App::Prove::Elasticsearch::Planner::Default::get_plans_needing_work = sub {
        my (%input) = @_;
        return [{ tests => ['a.t'] }] if $input{version} == 666;
        return [{ tests => ['b.t'] }] if $delay;
        $delay++;
        return [];
    };
    local *App::Prove::Elasticsearch::Queue::Default::_get_searcher   = sub { return shift->{'searcher'} = 'App::Prove::Elasticsearch::Searcher::ByName' };
    use warnings;

    my $obj = bless({ 'planner' => 'App::Prove::Elasticsearch::Planner::Default' },'App::Prove::Elasticsearch::Queue::Default');
    my %matrix = (
        cur_platforms => {
            'App::Prove::Elasticsearch::Provisioner::Fun'  => 'tickle',
            'App::Prove::Elasticsearch::Provisioner::Love' => 'hug',
        },
        cur_version => 666,
        unsatisfiable_platforms => ['moo'],
        version => 0,
        platforms => {
            'App::Prove::Elasticsearch::Provisioner::Fun'  => ['tickle','chase'],
            'App::Prove::Elasticsearch::Provisioner::Love' => ['hug','kiss'],
        },
    );

    my @qs = $obj->list_queues(%matrix);
    is_deeply(\@qs,[{ tests => ['a.t'] }],"When system is in the desired configuration, existing platform returned");

    $matrix{cur_version} = 999;
    @qs = $obj->list_queues(%matrix);
    is_deeply(\@qs,[{ tests => ['b.t'] }],"When system is NOT in the desired configuration, new platform returned");

}

{
    my $js = { version => 666, platforms => ['tickle', 'hug'] };
    is(App::Prove::Elasticsearch::Queue::Default->build_queue_name($js),"666ticklehug", "q name built correctly");
}
