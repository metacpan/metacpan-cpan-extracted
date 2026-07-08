use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/cas_clause_guards.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE example (id INTEGER PRIMARY KEY, name TEXT, revision INTEGER)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('example');
my $row = $h->insert({name => 'a', revision => 1});

like(
    dies { $h->row($row)->limit(1)->cas([qw/revision/], {revision => 2}) },
    qr/limit.*not currently supported/,
    "limit clause croaks",
);

like(
    dies { $h->row($row)->offset(1)->cas([qw/revision/], {revision => 2}) },
    qr/offset.*not currently supported/,
    "offset clause croaks",
);

like(
    dies { $h->row($row)->order_by('id')->cas([qw/revision/], {revision => 2}) },
    qr/order_by.*not currently supported/,
    "order_by clause croaks",
);

like(
    dies { $h->row($row)->distinct->cas([qw/revision/], {revision => 2}) },
    qr/distinct.*not currently supported/,
    "distinct clause croaks",
);

is($h->by_id($row->field('id'))->field('revision'), 1, "unsupported clause attempts do not update the row");

subtest structured_guard_warnings => sub {
    my $warn = warnings {
        $h->row($row)->cas({-and => [{revision => 1}]}, {name => 'b'});
    };

    like($warn->[0], qr/guard column \(revision\)/, "structured guard warning names the real field");
    unlike($warn->[0], qr/-and/, "structured guard warning does not name the operator key");
    is($row->field('name'), 'b', "non-advancing structured guard still applies the winning change");

    my $clean = warnings {
        $h->row($row)->cas({-and => [{revision => 1}]}, {revision => 2});
    };

    is($clean, [], "no warning when a structured guard advances");
    is($row->field('revision'), 2, "structured guard update advanced the guard field");
};

done_testing;
