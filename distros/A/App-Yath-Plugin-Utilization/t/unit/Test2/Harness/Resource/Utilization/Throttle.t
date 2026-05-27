use Test2::V0;

use Test2::Harness::Resource::Utilization::Throttle;
my $CLASS = 'Test2::Harness::Resource::Utilization::Throttle';

subtest construct => sub {
    my $r = $CLASS->new(cap => 5, window => 2);
    is($r->cap, 5);
    is($r->window, 2);
    is($r->bases, []);

    like(dies { $CLASS->new(cap => 0, window => 1) }, qr/cap.*positive integer/, 'reject zero cap');
    like(dies { $CLASS->new(cap => 5, window => 0) }, qr/window.*positive number/, 'reject zero window');
};

subtest parse_rule_entry => sub {
    my $r = $CLASS->_parse_rule_entry('5/2s');
    is($r, {cap => 5, window => 2}, 'cap/window');

    is($CLASS->_parse_rule_entry('5'),       {cap => 5, window => 1}, 'bare cap');
    is($CLASS->_parse_rule_entry('10/500ms'), {cap => 10, window => 0.5}, 'ms');
    is($CLASS->_parse_rule_entry('3/1m'),    {cap => 3, window => 60}, 'minute');

    my $multi = $CLASS->_parse_rule_entry('1/core,100mb/1s');
    is($multi->{cap}, 1);
    is($multi->{window}, 1);
    is($multi->{bases}, [{type => 'core'}, {type => 'ram', bytes => 100 * 1024**2}]);

    like(dies { $CLASS->_parse_rule_entry('garbage') }, qr/unrecognised rule entry/, 'bad entry');
    like(dies { $CLASS->_parse_rule_entry('0/1s') }, qr/cap.*positive integer/, 'zero cap rejected');
    like(dies { $CLASS->_parse_rule_entry('5/junk/1s') }, qr/unknown basis unit/, 'bad basis');
};

subtest available_simple => sub {
    my $r = $CLASS->new(cap => 2, window => 60);

    is($r->available({}), 1, 'first allowed');

    my $state = {};
    $r->assign({rel_file => 'a.t'}, $state);
    $r->record('j1', $state->{record});
    is($r->available({}), 1, 'second allowed');

    $state = {};
    $r->assign({rel_file => 'b.t'}, $state);
    $r->record('j2', $state->{record});
    is($r->available({}), 0, 'third defers (cap=2)');

    $r->release('j1');
    is($r->available({}), 1, 'allow after release');
};

subtest window_aging => sub {
    my $r = $CLASS->new(cap => 2, window => 0.05);

    my $state = {};
    $r->assign({rel_file => 'x'}, $state);
    $r->record('j1', $state->{record});
    $state = {};
    $r->assign({rel_file => 'y'}, $state);
    $r->record('j2', $state->{record});
    is($r->available({}), 0, 'at cap');

    select(undef, undef, undef, 0.08);
    is($r->available({}), 1, 'window aged out');
};

subtest token_count_with_bases => sub {
    local $Test2::Harness::Resource::Utilization::Throttle::DETECT_CORE_COUNT  = sub { 4 };
    local $Test2::Harness::Resource::Utilization::Throttle::READ_MEMINFO_AVAIL = sub { 1 * 1024**3 };    # 1 GiB

    my $r = $CLASS->new(cap => 1, window => 1, bases => [{type => 'core'}, {type => 'ram', bytes => 100 * 1024**2}]);
    my ($tokens, $win) = $r->_token_count;
    # cores=4, ram=1gb/100mb=10; min=4; cap*min=4
    is($tokens, 4, 'min(core,ram) * cap');
    is($win, 1, 'no halving needed');

    # Tight RAM forces halving
    local $Test2::Harness::Resource::Utilization::Throttle::READ_MEMINFO_AVAIL = sub { 60 * 1024**2 };
    ($tokens, $win) = $r->_token_count;
    # 100mb > 60mb, halve to 50mb (mult=2); 60/50 = 1 token; min(4,1)=1
    is($tokens, 1, 'one halving');
    is($win, 2, 'window doubled');

    # Even tighter -> two halvings
    local $Test2::Harness::Resource::Utilization::Throttle::READ_MEMINFO_AVAIL = sub { 20 * 1024**2 };
    ($tokens, $win) = $r->_token_count;
    # 100 > 20, halve to 50 (mult=2); 50 > 20, halve to 25 (mult=4); 25 > 20 still => 0
    is($tokens, 0, 'two halvings, basis still too large => zero tokens');
    is($win, 4, 'window quadrupled');
};

done_testing;
