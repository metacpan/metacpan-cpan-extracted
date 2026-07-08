use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# Runtime behavior of volatile columns on writes:
#  - a non-omitted volatile column the caller did not send (here a generated
#    column) is not trusted and not eagerly fetched; it lazily fetches the real
#    stored value on first access;
#  - a volatile + omitted column is cleared after the write and lazily re-fetched
#    on next access, picking up a value the database changed (here via an AFTER
#    trigger).

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

use DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);

subtest generated_volatile_lazy_readback => sub {
    my $dsn = "dbi:SQLite:dbname=$dir/gen.sqlite";
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE gen (id INTEGER PRIMARY KEY, name TEXT, label TEXT GENERATED ALWAYS AS (\'L:\' || name) VIRTUAL)');
        $dbh->disconnect;
    }

    # Autofill introspects: 'label' is a generated column, so it is auto-volatile.
    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

    # No auto_refresh: a volatile column the caller did not send is not eagerly
    # fetched (it is not in the stored data yet), but lazily fetches on access.
    my $row = $con->handle('gen')->insert({name => 'x'});
    ok(!exists $row->stored_data->{label}, "generated volatile column is not eagerly read back into stored data");
    is($row->field('label'), 'L:x', "generated volatile column lazily fetches its real stored value on access");
};

my $dsn = "dbi:SQLite:dbname=$dir/vol.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE things (id INTEGER PRIMARY KEY, name TEXT, secret TEXT, log TEXT)');
    # AFTER triggers change columns the caller sent; a re-SELECT (lazy fetch)
    # sees the change, so these exercise the omit+volatile clear-and-lazy path.
    $dbh->do('CREATE TRIGGER things_ins AFTER INSERT ON things BEGIN UPDATE things SET secret = \'DB:\' || NEW.name WHERE id = NEW.id; END');
    $dbh->do('CREATE TRIGGER things_upd AFTER UPDATE OF name ON things BEGIN UPDATE things SET log = \'U:\' || NEW.name WHERE id = NEW.id; END');
    $dbh->disconnect;
}

# A declared schema (no autofill) so we control the volatile+omit markers and do
# not trip introspection's trigger warning.
db voldb => sub {
    dialect 'SQLite';
    db_name 'main';
    connect sub { DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0}) };
};
orm volorm => sub {
    db 'voldb';
    schema volsch => sub {
        table things => sub {
            column id     => sub { primary_key; affinity 'numeric' };
            column name   => sub { affinity 'string' };
            column secret => sub { affinity 'string'; volatile; omit };
            column log    => sub { affinity 'string'; volatile; omit };
        };
    };
};

subtest omit_volatile_clear_and_lazy_on_insert => sub {
    my $con = orm('volorm')->connect;

    my $row = $con->handle('things')->insert({name => 'alice', secret => 'SENT'});

    ok(!exists $row->stored_data->{secret}, "the omit+volatile column is cleared from stored data (sent value not trusted)");
    is($row->field('secret'), 'DB:alice', "next access lazily fetches the real database value");
};

subtest omit_volatile_clear_and_lazy_on_update => sub {
    my $con = orm('volorm')->connect;

    my $row = $con->handle('things')->insert({name => 'bob'});
    $row->update({name => 'bob2'});

    ok(!exists $row->stored_data->{log}, "the omit+volatile column is cleared from stored data after update");
    is($row->field('log'), 'U:bob2', "next access lazily fetches the trigger-updated value");
};

done_testing;
