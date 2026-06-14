use Test2::V0 '!meta', '!pass';
use DBI;
use Data::Dumper;
use File::Temp qw/tempdir/;

BEGIN {
    skip_all "DBD::SQLite, DateTime, and DateTime::Format::SQLite are required"
        unless eval { require DBD::SQLite; require DateTime; require DateTime::Format::SQLite; 1 };
}

use DBIx::QuickORM::Util qw/mask unmask masked/;
require DBIx::QuickORM;

# ---- Util::Mask: lazy build, stringify-without-build, dump-hidden ----
subtest mask_basics => sub {
    my $built = 0;
    my $m = mask(string => "display-only", generator => sub { $built++; bless {v => 42}, 'Foo::Wrapped' });

    is("$m", "display-only", "stringifies to the display string");
    is($built, 0, "generator NOT run by stringification");
    ok(masked($m), "masked() is true for a mask");
    ok(!$m->qorm_mask_inflated, "not inflated yet");

    my $obj = unmask($m);
    is($built, 1, "generator ran once on first use");
    is(ref($obj), 'Foo::Wrapped', "got the wrapped object");
    ok($m->qorm_mask_inflated, "now inflated");

    unmask($m);
    is($built, 1, "memoized - generator not run again");

    is("$m", "display-only", "still stringifies to the display string after inflation");

    unlike(Dumper($m), qr/Foo::Wrapped|v.*42/, "wrapped object stays out of Data::Dumper output");

    ok(!masked("plain"), "masked() false for a non-mask");
    is(unmask("plain"), "plain", "unmask() passes non-masks through");
};

# ---- DateTime type over a real SQLite db ----
my $dir  = tempdir(CLEANUP => 1);
my $dsn  = "dbi:SQLite:dbname=$dir/dt.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE events (id INTEGER PRIMARY KEY, created DATETIME)');
    $dbh->do("INSERT INTO events (created) VALUES ('2020-01-02 03:04:05')");
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn}, auto_types => ['DateTime']);

subtest lazy_inflate => sub {
    my ($row) = $con->handle('events')->all;
    my $v = $row->field('created');

    ok(masked($v), "datetime column inflated to a mask");
    ok($v->isa('DBIx::QuickORM::Type::DateTime'), "isa the type (no build needed)");
    ok(!$v->qorm_mask_inflated, "isa(type) did not build the DateTime");

    is("$v", '2020-01-02 03:04:05', "stringifies to the database string");
    ok(!$v->qorm_mask_inflated, "stringify did not build the DateTime");

    is($v->year, 2020, "delegates a method to the DateTime (builds it now)");
    ok($v->qorm_mask_inflated, "now built");
    ok($v->isa('DateTime'), "isa('DateTime') via delegation");

    is("$v", '2020-01-02 03:04:05', "still the database string after the DateTime was built and used");
};

subtest deflate_without_build => sub {
    my ($row) = $con->handle('events')->all;
    my $v = $row->field('created');
    ok(!$v->qorm_mask_inflated, "fresh value not built");

    is($row->raw_field('created'), '2020-01-02 03:04:05', "deflates to the database string");
    ok(!$v->qorm_mask_inflated, "deflate did NOT build the DateTime");
};

subtest round_trip => sub {
    my $new = $con->insert(events => {created => '1999-12-31 23:59:59'});
    my $id  = $new->field('id');

    my $got = $con->by_id(events => $id)->field('created');
    is("$got", '1999-12-31 23:59:59', "inserted datetime round-trips");
};

done_testing;
