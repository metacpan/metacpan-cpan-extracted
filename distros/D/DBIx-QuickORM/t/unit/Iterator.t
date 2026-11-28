# Test origin: AI
use Test2::V0;

use Config qw/%Config/;
use DBIx::QuickORM::Iterator;

my $it = DBIx::QuickORM::Iterator->new(query => {rows => [{id => 1}, {id => 2}, {id => 3}], build => sub { "row $_[0]->{id}" }});

is($it->next,  'row 1', "next hands out the first row through build");
is($it->next,  'row 2', "then the second");
is($it->first, 'row 1', "first does not move the position");
is($it->last,  'row 3', "neither does last");
is($it->next,  'row 3', "next continues");
is($it->next,  undef,   "and is undef at the end");
is($it->next,  undef,   "and stays undef");
$it->reset;
is($it->next,  'row 1',                     "reset starts again");
is([$it->all], ['row 1', 'row 2', 'row 3'], "all hands out every row");
is($it->next,  'row 2',                     "without moving the position");
like(dies { $it->only }, qr/^only\(\) found more than one row/, "only croaks on more than one row");

my $plain = DBIx::QuickORM::Iterator->new(query => {rows => [{id => 1}]});
ref_is($plain->only, $plain->rows->[0], "Without build the row data is handed out; only gives the one row");

my $empty = DBIx::QuickORM::Iterator->new(query => {rows => []});
is([$empty->next, $empty->first, $empty->last, $empty->only], [undef, undef, undef, undef], "An empty iterator gives undef");
is([$empty->all],                                             [],                           "and no rows");

subtest single => sub {
    my $one = DBIx::QuickORM::Iterator->new(query => {rows => [{id => 1}]}, state => 'single');
    is($one->only, {id => 1}, "only works under single");
    is($one->next, {id => 1}, "next gives the row");
    is($one->next, undef, "and asking again past the end is not misuse");

    my $two = DBIx::QuickORM::Iterator->new(query => {rows => [{id => 1}, {id => 2}]}, state => 'single');
    is($two->next, {id => 1}, "The first row of a single iterator is fine");
    like(dies { $two->next }, qr/^This iterator is for a single row/, "asking for a second croaks");
    like(dies { $two->all },  qr/^This iterator is for a single row/, "and so does all");
    like(dies { $two->last }, qr/^This iterator is for a single row/, "and last");
};

subtest multi => sub {
    my $multi = DBIx::QuickORM::Iterator->new(query => {rows => [{id => 1}]}, state => 'multi');
    like(dies { $multi->only }, qr/^only\(\) cannot be used on a multi-row iterator/, "only always croaks under multi");
    is($multi->next, {id => 1}, "the rest works");
};

subtest pending => sub {
    my ($ready, @calls) = (0);
    my $pending = sub {
        return {
            ready   => sub { push @calls => 'ready'; $ready },
            collect => sub {
                push @calls => 'collect';
                ([{id => 1}, {id => 2}], sub { "row $_[0]->{id}" });
            },
            cancel => sub { push @calls => 'cancel' },
        };
    };

    my $it = DBIx::QuickORM::Iterator->new(query => {pending => $pending->()});
    is($it->rows, undef, "A pending iterator has no rows yet");
    ok(!$it->ready, "ready is false while the query is not ready");
    $ready = 1;
    ok($it->ready, "and true once it is");
    is(\@calls,    [qw/ready ready collect/], "which collects the rows at once");
    is([$it->all], ['row 1', 'row 2'],        "the rows are built as usual");
    ok($it->ready, "a collected iterator stays ready");
    undef $it;
    is(\@calls, [qw/ready ready collect/], "and is not cancelled when freed");

    @calls = ();
    $it    = DBIx::QuickORM::Iterator->new(query => {pending => $pending->()});
    is($it->next, 'row 1',     "next waits for the rows");
    is(\@calls,   ['collect'], "collecting without asking whether it is ready");

    @calls = ();
    $it    = DBIx::QuickORM::Iterator->new(query => {pending => $pending->()});
    $it->reset;
    is(\@calls,   [],      "reset does not wait for a pending iterator's rows");
    is($it->next, 'row 1', "and the reads still collect them");

    @calls = ();
    $it    = DBIx::QuickORM::Iterator->new(query => {pending => $pending->()});
    undef $it;
    is(\@calls, ['cancel'], "A pending iterator freed before collection cancels its query");

    @calls = ();
    $it    = DBIx::QuickORM::Iterator->new(query => {pending => {%{$pending->()}, collect => sub { push @calls => "collect"; die "boom\n" }}});
    like(dies { $it->all }, qr/^boom/, "A failed collection throws");
    like(dies { $it->$_ },  qr/^boom/, "and $_ throws it again") for qw/next all first last only/;
    ok(lives { $it->reset }, "reset only rewinds, so it does not throw");
    is(\@calls, ["collect"], "collecting only once");

    # Fork is emulated with threads on Windows, and _exit there ends the whole test.
    subtest inherited => sub {
        skip_all "fork is only emulated here" if $Config{d_pseudofork};
        $it = DBIx::QuickORM::Iterator->new(query => {pending => $pending->()});
        my $pid = fork // die "Could not fork: $!";
        unless ($pid) {
            my $err = (dies { $it->next }) // '';
            undef $it;
            require POSIX;
            POSIX::_exit($err =~ m/^This iterator's query was started in process \d+; it cannot be read in process $$/ && !grep({ $_ eq 'cancel' } @calls) ? 0 : 1);
        }
        waitpid($pid, 0);
        is($?, 0, "A child cannot collect or cancel an iterator it inherited");
    };

    subtest shared => sub {
        @calls = ();
        my $query = {pending => $pending->()};
        my $one   = DBIx::QuickORM::Iterator->new(query => $query);
        my $two   = DBIx::QuickORM::Iterator->new(query => $query);
        undef $one;
        is(\@calls,    [],      "Freeing one of two iterators over a pending query does not cancel it");
        is($two->next, 'row 1', "the other collects it");
        my $three = DBIx::QuickORM::Iterator->new(query => $query);
        is($three->next, 'row 1',     "a later iterator over the query reads the collected rows");
        is($two->next,   'row 2',     "each at its own position");
        is(\@calls,      ['collect'], "collected once for all of them");

        @calls = ();
        $query = {pending => $pending->()};
        $one   = DBIx::QuickORM::Iterator->new(query => $query);
        $two   = DBIx::QuickORM::Iterator->new(query => $query);
        undef $one;
        undef $two;
        is(\@calls, ['cancel'], "Freeing the last one cancels it");

        $query = {pending => {%{$pending->()}, collect => sub { die "boom\n" }}};
        $one   = DBIx::QuickORM::Iterator->new(query => $query);
        $two   = DBIx::QuickORM::Iterator->new(query => $query);
        like(dies { $one->all }, qr/^boom/, "A failed collection throws");
        like(dies { $two->all }, qr/^boom/, "for every iterator sharing the query");
    };

    like(
        dies {
            DBIx::QuickORM::Iterator->new(query => {pending => {ready => sub { 1 }}})
        },
        qr/^'pending' must be a hashref of ready, collect, and cancel code references/,
        "pending is checked"
    );
};

like(dies { DBIx::QuickORM::Iterator->new(rows  => []) }, qr/^'query' must be a hashref/, "query is required");
like(dies { DBIx::QuickORM::Iterator->new(query => {rows => {}}) },                  qr/^'rows' must be an arrayref/,                  "rows must be an arrayref");
like(dies { DBIx::QuickORM::Iterator->new(query => {rows => []}, state => 'many') }, qr/^'state' must be 'single', 'multi', or undef/, "state is checked");
like(dies { DBIx::QuickORM::Iterator->new(query => {rows => [], build => 'x'}) },    qr/^'build' must be a code reference/,            "build must be code");

done_testing;
