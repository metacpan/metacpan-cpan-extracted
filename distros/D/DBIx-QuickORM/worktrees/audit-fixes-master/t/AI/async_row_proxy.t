use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises the DBIx::QuickORM::Row::Async proxy against a mock async
# statement handle: DOES/isa/can forwarding, validity delegation after the
# proxy swaps itself out, the invalid path when no data arrives, and cancel.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;
require DBIx::QuickORM::Row;
require DBIx::QuickORM::Row::Async;

# A minimal in-memory async statement handle. Throwaway test scaffolding,
# not a real namespace worth its own file.
package My::Mock::Async {
    use Role::Tiny::With;
    with 'DBIx::QuickORM::Role::Async';

    sub new { my $class = shift; bless {got_result => 0, done => 0, ready => 0, rows => [], @_}, $class }

    sub connection { $_[0]->{connection} }
    sub source     { $_[0]->{source} }
    sub dialect    { $_[0]->{connection}->dialect }
    sub only_one   { 1 }
    sub got_result { $_[0]->{got_result} }
    sub result     { $_[0] }
    sub ready      { $_[0]->{ready} }
    sub done       { $_[0]->{done} }
    sub set_done   { $_[0]->{done} = 1 }
    sub clear      { }
    sub next       { my $self = shift; $self->{got_result} = 1; shift @{$self->{rows}} }

    sub cancel_supported { 1 }
    sub cancel           { $_[0]->{cancelled}++; $_[0]->{done} = 1 }
}

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/async.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE items (item_id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->do("INSERT INTO items (item_id, name) VALUES (1, 'one'), (2, 'two'), (3, 'three')");
    $dbh->disconnect;
}

my $con    = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $source = $con->source('items');

sub mock_proxy {
    my %params = @_;
    my $rows = delete $params{rows} // [];
    my $async = My::Mock::Async->new(connection => $con, source => $source, rows => $rows);
    my $proxy = DBIx::QuickORM::Row::Async->new(async => $async, %params);
    return ($proxy, $async);
}

subtest pending_proxy_without_row_class => sub {
    my ($proxy, $async) = mock_proxy(rows => [{item_id => 1, name => 'one'}]);

    ok(lives { $proxy->isa('Some::Other::Class') }, "isa does not crash without row_class");
    ok(lives { $proxy->can('nonexistent_method') }, "can does not crash without row_class");
    ok(lives { $proxy->DOES('DBIx::QuickORM::Role::Row') }, "DOES does not crash without row_class");

    ok($proxy->isa('DBIx::QuickORM::Row'), "proxy claims to be a row");
    ok($proxy, "pending proxy is true in boolean context");
};

subtest pending_proxy_with_row_class => sub {
    my ($proxy, $async) = mock_proxy(rows => [{item_id => 1, name => 'one'}], row_class => 'DBIx::QuickORM::Row');

    ok($proxy->DOES('DBIx::QuickORM::Role::Row'), "DOES forwards to the row class while pending");
    ok($proxy->can('field'), "can forwards to the row class while pending");
    ok($proxy->isa('DBIx::QuickORM::Row'), "isa true for the row class");
};

subtest materialized_proxy_forwards => sub {
    my ($proxy, $async) = mock_proxy(rows => [{item_id => 2, name => 'two'}]);
    $async->{ready} = 1;

    ok($proxy->DOES('DBIx::QuickORM::Role::Row'), "DOES true once materialized");
    ref_ok($proxy, 'HASH');
    isa_ok($proxy, ['DBIx::QuickORM::Row'], "swapped out to a real row");

    ok($proxy->is_valid, "is_valid delegates to the materialized row");
    ok(!$proxy->is_invalid, "is_invalid delegates to the materialized row");
    is($proxy->field('name'), 'two', "field access works on the materialized row");
};

subtest ready_empty_resolves_opportunistically => sub {
    # A ready-but-empty result must read as false / ready WITHOUT another method
    # call poking the proxy into materializing first.
    my ($proxy, $async) = mock_proxy(rows => []);
    $async->{ready} = 1;
    ok(!$proxy, "a ready-but-empty proxy is false in boolean context without being poked");

    my ($proxy2, $async2) = mock_proxy(rows => []);
    $async2->{ready} = 1;
    ok(defined($proxy2->ready), "ready() reports a defined (ready) result for a ready-but-empty query");
    ok($proxy2->ready, "ready() is true once the empty result has arrived");

    # A still-pending proxy stays truthy.
    my ($pending) = mock_proxy(rows => [{item_id => 1, name => 'one'}]);
    ok($pending, "a pending proxy is still true in boolean context");
};

subtest empty_result_invalidates => sub {
    my ($proxy, $async) = mock_proxy(rows => []);
    $async->{ready} = 1;

    ok($proxy->is_invalid, "proxy is invalid when the query returned no data");
    ok(!$proxy->is_valid, "is_valid is false");
    ok(!$proxy, "invalid proxy is false in boolean context");
    like(dies { $proxy->field('name') }, qr/This async row is not valid/, "method calls croak on an invalid proxy");
};

subtest cancel => sub {
    my ($proxy, $async) = mock_proxy(rows => [{item_id => 3, name => 'three'}]);

    $proxy->cancel;
    is($async->{cancelled}, 1, "cancel was forwarded to the async handle");
    ok($proxy->is_invalid, "cancelled proxy is invalid");
    ok(!$proxy->is_valid, "cancelled proxy is not valid");
};

done_testing;
