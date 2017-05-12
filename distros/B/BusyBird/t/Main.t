use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Memory::Cycle;
use lib "t";
use testlib::Timeline_Util qw(status sync);
use testlib::Main_Util qw(create_main);
use BusyBird::Test::StatusStorage qw(:status);
use BusyBird::StatusStorage::SQLite;
use BusyBird::Timeline;
use BusyBird::Log;
use utf8;

BEGIN {
    use_ok('BusyBird::Main');
}

$BusyBird::Log::Logger = undef;

sub test_watcher_basic {
    my ($watcher) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    isa_ok($watcher, 'BusyBird::Watcher');
    can_ok($watcher, 'active', 'cancel');
}

sub create_memory_storage {
    return BusyBird::StatusStorage::SQLite->new(path => ':memory:');
}

{
    my $main = new_ok('BusyBird::Main');
    my $storage = create_memory_storage();
    $main->set_config(default_status_storage => $storage);
    is($main->get_config("default_status_storage"), $storage, 'setting default_status_storage OK');
}

{
    my $main = create_main();
    is_deeply([$main->get_all_timelines], [], 'at first, no timelines');

    my $tl1 = $main->timeline('test1');
    isa_ok($tl1, 'BusyBird::Timeline', 'timeline() creates a timeline');
    is($tl1->name, 'test1', "... its name is test1");
    is_deeply([$main->get_all_timelines], [$tl1], 'test1 is installed,.');
    is($main->timeline('test1'), $tl1, 'timeline() returns the installed timeline');
    is($main->get_timeline('test1'), $tl1, 'get_timeline() returns the installed timeline');

    is($main->get_timeline('foobar'), undef, 'get_timeline() returns undef if the timeline is not installed.');
    my $tl2 = BusyBird::Timeline->new(name => 'foobar', storage => create_memory_storage());
    $main->install_timeline($tl2);
    is($main->get_timeline('foobar'), $tl2, 'install_timeline() installs a timeline');
    is($main->timeline('foobar'), $tl2, 'timeline() returns the installed timeline');
    is_deeply([$main->get_all_timelines], [$tl1, $tl2], "get_all_timelines() return the two timelines");

    is($main->uninstall_timeline('hogehoge'), undef, 'uninstall_timeline() returns undef it the timeline is not installed');
    is($main->uninstall_timeline('test1'), $tl1, 'uninstall test1 timeline');
    is($main->get_timeline('test1'), undef, 'now test1 is not installed');
    is_deeply([$main->get_all_timelines], [$tl2], 'now only foobar is installed.');

    my $tl3 = BusyBird::Timeline->new(name => 'foobar', storage => create_memory_storage());
    $main->install_timeline($tl3);
    is($main->get_timeline('foobar'), $tl3, 'install_timeline() replaces the old timeline with the same name');
    is($main->timeline('foobar'), $tl3, 'timeline() returns the installed timeline');
}

{
    my $main = create_main();
    $main->timeline($_) foreach reverse 1..20;
    is_deeply(
        [map { $_->name } $main->get_all_timelines],
        [reverse 1..20],
        'order of timelines from get_all_timelines() is preserved.'
    );
}

{
    my $main = create_main();
    my $storage1 = $main->get_config("default_status_storage");
    my $storage2 = create_memory_storage();

    my $tl1 = $main->timeline('1');
    $main->set_config(default_status_storage => $storage2);
    my $tl2 = $main->timeline('2');
    sync($tl1, 'add_statuses', statuses => [status(10)]);
    sync($tl2, 'add_statuses', statuses => [status(20)]);
    my $error;
    ($error, my ($s11)) = sync($storage1, 'get_statuses', timeline => 1, count => 'all');
    ($error, my ($s12)) = sync($storage1, 'get_statuses', timeline => 2, count => 'all');
    ($error, my ($s21)) = sync($storage2, 'get_statuses', timeline => 1, count => 'all');
    ($error, my ($s22)) = sync($storage2, 'get_statuses', timeline => 2, count => 'all');
    test_status_id_set($s11, [10], 'status 10 is saved to storage 1');
    test_status_id_set($s12, [],   'no status in timeline 2 is saved to storage 1');
    test_status_id_set($s21, [],   'no status in timeline 1 is saved to storage 2');
    test_status_id_set($s22, [20], 'status 20 is saved to storage 2');
}

{
    note('--- -- watch_unacked_counts');
    my $main = create_main();
    memory_cycle_ok($main, 'no cyclic ref in main');
    $main->timeline('a');
    sync($main->timeline('b'), 'add_statuses', statuses => [status(1), status(2, 2)]);
    sync($main->timeline('c'), 'add_statuses', statuses => [status(3, -3), status(4,0), status(5)]);
    sync($main->timeline('a'), 'get_statuses', count => 1); ## go into event loop
    note('--- watch immediate');
    my %exp_counts = (
        a => {total => 0},
        b => {total => 2, 0 => 1, 2 => 1},
        c => {total => 3, 0 => 2, -3 => 1}
    );
    foreach my $case (
        {label => "total a", watch => {level => 'total', assumed => {a => 0}}, exp_callback => 0},
        {label => "total a,b,c", watch => {level => 'total', assumed => {a => 0, b => 0, c => 0}}, exp_callback => 1},
        {label => "level omitted callbacked", watch => {assumed => {c => 2}}, exp_callback => 1, exp_tls => ['c']},
        {label => "level omitted not callbacked", watch => {assumed => {c => 3}}, exp_callback => 0},
        {label => "lv.0 correct", watch => {level => 0, assumed => {b => 1, c => 2}}, exp_callback => 0},
        {label => "lv.0 wrong", watch => {level => 0, assumed => {b => 1, c => 1}}, exp_callback => 1, exp_tls => ['c']},
        {label => "lv.2 correct", watch => {level => 2, assumed => {a => 0, b => 1, c => 0}}, exp_callback => 0},
        {label => "lv.2 wrong", watch => {level => 2, assumed => {a => 4, c => 0}}, exp_callback => 1, exp_tls => ['a']},
        {label => "lv.-1 correct", watch => {level => -1, assumed => {b => 0, c => 0}}, exp_callback => 0},
        {label => "lv.-3 correct", watch => {level => -3, assumed => {a => 0, c => 1}}, exp_callback => 0},
        {label => "lv.-3 wrong", watch => {level => -3, assumed => {b => 4, c => 0}}, exp_callback => 1},
        {label => "junk level", watch => {level => 'junk', assumed => {a => 0, b => 0}}, exp_callback => 1}
    ) {
        my $label = defined($case->{label}) ? $case->{label} : "";
        my $callbacked = 0;
        my $inside_w;
        my $watcher = $main->watch_unacked_counts(%{$case->{watch}}, callback => sub {
            my ($error, $w, $got_counts) = @_;
            $callbacked = 1;
            is($error, undef, "$label: watch_unacked_counts succeed");
            my @keys = keys %$got_counts;
            cmp_ok(int(@keys), ">=", 1, "$label: at least 1 key obtained.");
            if(defined($case->{exp_tls})) {
                foreach my $exp_tl (@{$case->{exp_tls}}) {
                    ok(defined($got_counts->{$exp_tl}), "timeline $exp_tl is included in result");
                }
            }
            foreach my $key (@keys) {
                is_deeply($got_counts->{$key}, $exp_counts{$key}, "$label: unacked counts for $key OK");
            }
            $w->cancel();
            $inside_w = $w;
        });
        test_watcher_basic($watcher);
        memory_cycle_ok($main, "$label: no cyclic ref in main");
        memory_cycle_ok($watcher, "$label: no cyclic ref in watcher");
        is($callbacked, $case->{exp_callback}, "callbacked is $case->{exp_callback}");
        if($callbacked) {
            is($inside_w, $watcher, "$label: watcher inside is the same as the watcher outside");
        }
        $watcher->cancel();
    }

    {
        note('--- watch persistent and delayed');
        my %results;
        my $callbacked;
        my $reset = sub {
            %results = (a => [], b => [], c => []);
            $callbacked = 0;
        };
        my $callback_func = sub {
            my ($error, $w, $unacked_counts) = @_;
            is($error, undef, 'watch_unacked_counts succeed');
            push(@{$results{$_}}, $unacked_counts->{$_}) foreach keys %$unacked_counts;
            $callbacked++;
        };
        $reset->();
        my $watcher = $main->watch_unacked_counts(
            level => 'total', assumed => {a => 0, b => 2, c => 3}, callback => $callback_func
        );
        memory_cycle_ok($main, "no cyclic ref in main");
        memory_cycle_ok($watcher, 'no cyclic ref in watcher');
        sync($main->timeline('b'), 'ack_statuses');
        sync($main->timeline('c'), 'delete_statuses', ids => [4]);
        sync($main->timeline('a'), 'add_statuses', statuses => [status(6, 1)]);
        sync($main->timeline('a'), 'get_statuses', count => 1); ## go into event loop
        is($callbacked, 3, "3 callbacked");
        is_deeply(\%results, {a => [{total => 1, 1 => 1}], b => [{total => 0}], c => [{total => 2, 0 => 1, -3 => 1}]},
                  "results OK");
        $watcher->cancel();

        $reset->();
        $watcher = $main->watch_unacked_counts(level => 1, assumed => {a => 1, b => 0, c => 1}, callback => $callback_func);
        sync($main->timeline('b'), 'put_statuses', mode => 'insert', statuses => [status(7, 1)]);
        sync($main->timeline('c'), 'put_statuses', mode => 'update', statuses => [status(3, 1)]);
        sync($main->timeline('a'), 'put_statuses', mode => 'update', statuses => [status(6)]);
        sync($main->timeline('a'), 'get_statuses', count => 1); ## go into event loop
        is($callbacked, 3, '3 callbacked');
        is_deeply(\%results, {a => [{total => 1, 0 => 1}], b => [{total => 1, 1 => 1}], c => [{total => 2, 0 => 1, -3 => 1}]},
                  "results OK");
        $watcher->cancel();
    }
}

{
    note('--- watch_unacked_counts: junk input');
    my $main = create_main();
    $main->timeline('a');
    my %a = (assumed => {a => 1});
    foreach my $case (
        {label => 'empty assumed', exp => qr/assumed/, args => {level => 'total', assumed => {}, callback => sub {}}},
        {label => 'watching only unknown timeline', exp => qr/assumed/,
         args => {level => 'total', assumed => {b => 1}, callback => sub {}}},
        {label => 'assumed str', exp => qr/assumed/, args => {assumed => 'hoge', callback => sub {}}},
        {label => 'no assumed', exp => qr/assumed/, args => {callback => sub {}}},
        {label => 'assumed undef', exp => qr/assumed/, args => {assumed => undef, callback => sub {}}},
        {label => "assumed array-ref", exp => qr/assumed/, args => {assumed => [], callback => sub {}}},
        {label => "assumed code-ref", exp => qr/assumed/, args => {assumed => sub {}, callback => sub {}}},
        {label => 'no callback', exp => qr/callback/, args => {%a}},
        {label => 'callback undef', exp => qr/callback/, args => {%a, callback => undef}},
        {label => 'callback str', exp => qr/callback/, args => {%a, callback => 'foobar'}},
        {label => 'callback array-ref', exp => qr/callback/, args => {%a, callback => []}},
        {label => 'callback hash-ref', exp => qr/callback/, args => {%a, callback => {}}},
    ) {
        like(exception { $main->watch_unacked_counts(%{$case->{args}}) },
             $case->{exp}, "watch_unacked_counts: $case->{label}: raises an exception");
    }
    my $w;
    is(exception { $w = $main->watch_unacked_counts(assumed => {a => 0, b => 0}, callback => sub {}) },
       undef, 'unknown timeline is ignored.');
    ok($w->active, 'watcher is active.');
    $w->cancel();
}

{
    note('--- Unicode timeline names');
    my $main = create_main();
    my $tl_name = 'ほげ タイムライン';
    isa_ok($main->timeline($tl_name), "BusyBird::Timeline", "returned from timeline()");
    isa_ok($main->get_timeline($tl_name), "BusyBird::Timeline", "returned from get_timeline()");
    my $callbacked = 0;
    my $watcher = $main->watch_unacked_counts(
        level => 'total', assumed => {
            $tl_name => 10
        },
        callback => sub {
            my ($e, $w, $tl_unacked_counts) = @_;
            $callbacked = 1;
            is($e, undef, "watch unacked counts succeed");
            ok($w->active, "watcher still active");
            is_deeply($tl_unacked_counts, {$tl_name => { total => 0 }}, "unacked counts results OK");
            $w->cancel;
        }
    );
    ok($callbacked, "callbacked");
    ok(!$watcher->active, "watcher is inactive now");
}

{
    note('--- timeline names with slashes');
    my $main = create_main();
    my @logs = ();
    local $BusyBird::Log::Logger = sub { push @logs, \@_ };
    my $storage = $main->get_config("default_status_storage");
    foreach my $ng_name ("/", "/hoge", "foo/bar", "///", " / ") {
        @logs = ();
        my $timeline = $main->timeline($ng_name);
        is scalar($main->get_all_timelines), 0, "timeline $ng_name: timeline(): no timeline installed";
        is $timeline->name, $ng_name, "timeline $ng_name: timeline is created and returned";
        like $logs[0][0], qr/^warn/, "timeline $ng_name: warning is logged";
        like $logs[0][1], qr/invalid.*name/i, "timeline $ng_name: warning message OK";

        @logs = ();
        $timeline = BusyBird::Timeline->new(name => $ng_name, storage => $storage);
        $main->install_timeline($timeline);
        is scalar($main->get_all_timelines), 0, "timeline $ng_name: install_timeline(): no timeline installed";
        like $logs[0][0], qr/^warn/, "timeline $ng_name: warning is logged";
        like $logs[0][1], qr/invalid.*name/i, "timeline $ng_name: warning message OK";
    }
}

{
    note('--- create_timeline');
    my $main = create_main();
    my $timeline = $main->create_timeline("hoge");
    is $timeline->name, "hoge", "create a timeline named hoge";
    is scalar($main->get_all_timelines), 0, "no timeline installed";
    
    my $another_timeline = $main->create_timeline("hoge");
    is $timeline->name, "hoge", "create another hoge";
    isnt $another_timeline, $timeline, "create_timeline() creates different Timeline objects";
}

{
    note("--- synopsis");
    my $main = create_main();

    my $foo = $main->timeline("foo");
    my $bar = $main->timeline("bar");

    my @all_timelines = $main->get_all_timelines;
    is $all_timelines[0]->name, "foo", "name foo ok";
    is $all_timelines[1]->name, "bar", "name bar ok";

    $main->set_config(time_zone => "UTC");
    $foo->set_config(time_zone => "+0900");

    is $main->get_timeline_config("foo", "time_zone"), "+0900", "foo time_zone ok";
    is $main->get_timeline_config("bar", "time_zone"), "UTC", "bar time_zone ok";
}

{
    note("--- example: watch_unacked_counts");
    my $main = create_main();
    
    sync $main->timeline("TL1"), "add_statuses", statuses => [status(0, 0), status(1, 2)];
    $main->timeline("TL2");
    sync $main->timeline("TL3"), "add_statuses", statuses => [map { status($_ + 100) } 1..5];

    my $watcher = $main->watch_unacked_counts(
        level => "total",
        assumed => { TL1 => 0, TL2 => 0, TL3 => 5 },
        callback => sub {
            my ($error, $w, $tl_unacked_counts) = @_;
            $w->cancel();
            is_deeply $tl_unacked_counts, {
                TL1 => {
                    total => 2,
                    0     => 1,
                    2     => 1,
                },
            }, "watch result ok";
        }
    );
    sync $main->timeline("TL1"), "get_statuses", count => 1; ## go into event loop
}

done_testing();
