use Test::More;
use Test::Requires qw(DBD::SQLite);
use AnyEvent::DBI::Abstract;

sub sync(&;&) {
    my $block = shift;
    my $cb = shift;
    my $cv = AnyEvent->condvar;
    $cv->cb(sub { $cb->($_[0]->recv) }) if $cb;
    $block->($cv);
    $cv->recv;
}

my $dbh = AnyEvent::DBI::Abstract->new("dbi:SQLite:dbname=t/test.db", "", "");
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

done_testing;

END { unlink "t/test.db" }
