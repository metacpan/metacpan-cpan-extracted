use Test::More;
use Test::Requires qw(DBD::SQLite);
use AnyEvent::DBI::Abstract::Limit;

sub sync(&;&) {
    my $block = shift;
    my $cb = shift;
    my $cv = AnyEvent->condvar;
    $cv->cb(sub { $cb->($_[0]->recv) }) if $cb;
    $block->($cv);
    $cv->recv;
}

my $dbh = AnyEvent::DBI::Abstract::Limit->new("dbi:SQLite:dbname=t/test.db", "", "");
sync { $dbh->exec("create table foo (id integer, foo text)", @_) };

sync { $dbh->select("foo", @_) } sub {
    my($dbh, $rows, $rv) = @_;
    is_deeply $rows, [];
};

sync { $dbh->insert("foo", { id => 1, foo => "value" }, @_) };

sync { $dbh->select("foo", @_) } sub {
    my($dbh, $rows, $rv) = @_;
    is_deeply $rows, [ [ 1, "value" ] ];
};

for my $i (2 .. 10) {
    sync { $dbh->insert("foo", { id => $i, foo => "value - $i" }, @_) };
}

sync { $dbh->select("foo", @_) } sub {
    my($dbh, $rows, $rv) = @_;
    is scalar @$rows, 10;
};
sync { $dbh->select("foo", '*', {}, {-asc => 'id'}, 3, 4, @_) } sub {
    my($dbh, $rows, $rv) = @_;
    is_deeply $rows, [
        [ 5, 'value - 5' ],
        [ 6, 'value - 6' ],
        [ 7, 'value - 7' ],
    ];
};
done_testing;

END { unlink "t/test.db" }
