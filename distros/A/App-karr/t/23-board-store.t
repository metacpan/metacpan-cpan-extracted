use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use YAML::XS qw( Dump Load );

use App::karr::Git;
use App::karr::Task;

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is($rc, 0, "@cmd");
}

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
    return $repo;
}

subtest 'board store merges sparse config overrides from refs' => sub {
    my $repo = _init_repo();
    my $git = App::karr::Git->new( dir => $repo );

    $git->write_ref(
        'refs/karr/config',
        Dump({
            version => 1,
            board   => { name => 'Ref Board' },
            defaults => { priority => 'high' },
        }),
    );
    $git->write_ref( 'refs/karr/meta/next-id', "7\n" );

    require App::karr::BoardStore;
    my $store = App::karr::BoardStore->new( git => $git );

    my $config = $store->load_config;
    is( $config->{board}{name}, 'Ref Board', 'stored board name overrides default' );
    is( $config->{defaults}{priority}, 'high', 'stored default priority overrides default' );
    is( $config->{defaults}{status}, 'backlog', 'missing default values come from code defaults' );
    is( $store->peek_next_id, 7, 'next-id metadata is read from its own ref' );
};

subtest 'board store persists only config overrides and task refs' => sub {
    my $repo = _init_repo();
    my $git = App::karr::Git->new( dir => $repo );

    require App::karr::BoardStore;
    my $store = App::karr::BoardStore->new( git => $git );

    my $config = $store->load_config;
    $config->{board}{name} = 'Custom Name';
    $config->{claim_timeout} = '30m';
    $store->save_config($config);

    my $raw = Load( $git->read_ref('refs/karr/config') );
    is_deeply(
        $raw,
        {
            version => 1,
            board => { name => 'Custom Name' },
            claim_timeout => '30m',
        },
        'config ref stores only overrides plus version'
    );

    my $task = App::karr::Task->new(
        id => 3,
        title => 'Ref-backed task',
        status => 'todo',
        priority => 'high',
        class => 'standard',
        body => 'Stored in refs',
    );
    $store->save_task($task);

    my $loaded = $store->find_task(3);
    isa_ok( $loaded, 'App::karr::Task' );
    is( $loaded->title, 'Ref-backed task', 'task roundtrips through refs' );

    my @refs = $store->list_karr_refs;
    ok( grep( $_ eq 'refs/karr/config', @refs ), 'config ref is listed' );
    ok( grep( $_ eq 'refs/karr/tasks/3/data', @refs ), 'task ref is listed' );
};

subtest 'next-id allocation and namespace deletion work via refs' => sub {
    my $repo = _init_repo();
    my $git = App::karr::Git->new( dir => $repo );

    require App::karr::BoardStore;
    my $store = App::karr::BoardStore->new( git => $git );

    is( $store->allocate_next_id, 1, 'first allocated id is 1' );
    is( $store->allocate_next_id, 2, 'second allocated id is 2' );
    is( $store->peek_next_id, 3, 'next-id ref tracks the next free id' );

    $git->write_ref( 'refs/karr/log/test', qq({"action":"create"}) );
    my @before = $store->list_karr_refs;
    ok( @before >= 2, 'refs exist before deletion' );

    $store->delete_all_karr_refs;
    is_deeply( [ $store->list_karr_refs ], [], 'delete_all_karr_refs removes the whole namespace' );
};

done_testing;
