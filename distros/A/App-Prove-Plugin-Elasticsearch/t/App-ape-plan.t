use strict;
use warnings;

package Test::GrapeApe::Planner;

use parent qw{Test::Class};
use Test::More;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture};

use App::ape::plan;

sub test_new : Test(5) {
    is(App::ape::plan->new(),2,"No args returns bad exit code");
    is(App::ape::plan->new(qw{--version 666 --show --prompt}),3,"Bad exit code returned due to incompatible options");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub{return {}};
    use warnings;

    is(App::ape::plan->new(qw{--version 666}),4,"Bad exit code returned due to insufficient configuration");

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Utils::process_configuration = sub {return { 'server.host' => 'bogus', 'server.port' => 'bogus'}};
    local *App::Prove::Elasticsearch::Utils::require_platformer = sub { return 'Grape::Ape::BananaBoat' };
    local *Grape::Ape::BananaBoat::get_platforms = sub { return ['grape', 'ape'] };
    local *App::Prove::Elasticsearch::Utils::require_planner = sub { return 'Grape::Ape::BananaBoat' };
    local *Grape::Ape::BananaBoat::check_index = sub {};
    local *App::Prove::Elasticsearch::Utils::require_queue = sub { return 'Grape::Ape::BananaBoat' };
    local *Grape::Ape::BananaBoat::new = sub { return bless({},'Grape::Ape::BananaBoat')};
    local *Grape::Ape::BananaBoat::_get_searcher = sub { return 'Grape::Ape::LostBananaPeel' };
    local *App::Prove::State::new = sub { return bless({},'App::Prove::State') };
    local *App::Prove::State::extensions = sub {};
    local *App::Prove::State::get_tests = sub { my (undef,undef,@ret) = @_; return @ret };
    use warnings;

    my $obj = App::ape::plan->new(qw{--version 666 --ext .t --platform zippy });

    my $expected = {
       'allplatforms' => undef,
       'exts' => [
         '.t'
       ],
       'name' => undef,
       'pairwise' => undef,
       'platforms' => [
         'zippy'
       ],
       'prompt' => undef,
       'recurse' => undef,
       'replay' => undef,
       'requeue' => undef,
       'show' => undef,
       'version' => '666'
    };

    isa_ok($obj,"App::ape::plan");
    is_deeply($obj->{options},$expected,"args appear to parse correctly");
}

sub test_run : Test(5) {
    no warnings qw{redefine once};
    local *App::ape::plan::_build_plans = sub { return ( { noop => 1 } ) };
    local *Banana::In::Tailpipe::get_plan_status = sub {};
    local *App::ape::plan::_print_plan = sub {};
    use warnings;

    my $test_obj = bless({
       planner => 'Banana::In::Tailpipe',
       queue => bless({},'Banana::In::Tailpipe'),
       conf => {},
       cases => [],
       options => {
            show => 1,
            requeue => 1,
       },
    },"App::ape::plan");

    is( $test_obj->run(), 0, "Can run all the way through OK in --show mode");

    $test_obj->{options}{show} = 0;
    $test_obj->{options}{prompt} = 0;

    no warnings qw{redefine once};
    local *Banana::In::Tailpipe::add_plan_to_index = sub { return 0 };
    local *Banana::In::Tailpipe::queue_jobs = sub { return 0 };
    use warnings;

    is( $test_obj->run(), 0, "Can run all the way through OK in no-show no-prompt mode");

    $test_obj->{options}{prompt} = 1;
    $test_obj->{options}{requeue} = 0;

    no warnings qw{redefine once};
    local *IO::Prompter::prompt = sub { return 1 };
    use warnings;

    is( $test_obj->run(), 0, "Can run all the way through OK in prompt mode: noop");

    no warnings qw{redefine once};
    local *App::ape::plan::_build_plans = sub { return ( { noop => 0 } ) };
    use warnings;

    is( $test_obj->run(), 0, "Can run all the way through OK in prompt mode: normal execution");

    no warnings qw{redefine once};
    local *Banana::In::Tailpipe::add_plan_to_index = sub { return 1 };
    local *Banana::In::Tailpipe::queue_jobs = sub { return 1 };
    use warnings;

    is( $test_obj->run(), 2, "Can run all the way through and get bad exit code when add plan/queue fails");

}

sub test_build_plans: Test(1) {

}

sub test_build_plan: Test(2) {
    my $planner = 'Grape::Ape::FecesHurl';
    my $tests = ['a', 'b', 'c'];
    my %options = ( 'exists' => 1 );

    no warnings qw{redefine once};
    local *Grape::Ape::FecesHurl::get_plan = sub { my %options = @_; return $options{'exists'} };
    local *Grape::Ape::FecesHurl::make_plan = sub { return 'new' };
    local *Grape::Ape::FecesHurl::make_plan_update = sub { return 'update' };
    use warnings;

    is(App::ape::plan::_build_plan($planner,$tests,%options),'update', "Can make update plan correctly");
    $options{exists} = 0;
    is(App::ape::plan::_build_plan($planner,$tests,%options),'new', "Can make new plan correctly");
}

sub test_print_plan: Test(7) {
    my $plan = {
        'noop'      => 1,
        'name'      => 'whee',
        'version'   => 666,
        'platforms' => ['a', 'b'],
        'pairwise'  => 'true',
        'created'   => 'now',
        'tests'     => ['a','b'],
        'update'    => {
            'subtraction' => { tests => ['c'] },
            'addition'    => { tests => ['d'] },
        },
    };
    like(capture { App::ape::plan::_print_plan($plan) },qr/already exists/i,"When there's nothing to do, user is notified");

    like(capture { App::ape::plan::_print_plan($plan,1) }, qr/remove/i, "Force --show prints noop plan details (removal)");
    like(capture { App::ape::plan::_print_plan($plan,1) }, qr/add/i, "Force --show prints noop plan details (removal)");

    $plan->{noop} = 0;
    $plan->{state} = [
        { name => 'a', test_version => 666, body => 'wheee', status => 'SIPPYCUP', steps => ['a','b','c'], steps_planned => 3 },
        { name => 'b', test_version => 666, body => 'wheee', status => 'UNTESTED'}
    ];

    like(capture { App::ape::plan::_print_plan($plan) }, qr/sippycup/i, "Test results show up");
    unlike(capture { App::ape::plan::_print_plan($plan) }, qr/wheee/i, "Test bodies don't show up by default");
    like(capture { App::ape::plan::_print_plan($plan) }, qr/untested/i, "Untested results display correctly");

    $plan->{replay} = ['a','b'];
    like(capture { App::ape::plan::_print_plan($plan) }, qr/wheee/i, "Test bodies show up by when replays exist");
}

__PACKAGE__->runtests();
