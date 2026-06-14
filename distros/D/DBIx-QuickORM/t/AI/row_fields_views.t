use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises the merged field views in DBIx::QuickORM::Row: a staged undef
# (pending NULL) must win over a defined stored value in fields() and
# raw_fields().

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/fields.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE notes (note_id INTEGER PRIMARY KEY, title TEXT NOT NULL, body TEXT)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h   = $con->handle('notes');

subtest staged_null_visible_in_fields => sub {
    my $row = $h->insert({title => 'hello', body => 'world'});

    $row->field(body => undef);

    is($row->field('body'), undef, "field() shows the staged NULL");
    is($row->fields->{body}, undef, "fields() shows the staged NULL");
    is($row->raw_fields->{body}, undef, "raw_fields() shows the staged NULL");
    is($row->stored_field('body'), 'world', "stored view still has the old value");

    is($row->fields->{title}, 'hello', "untouched fields still come from stored data");

    $row->save;
    is($row->stored_field('body'), undef, "NULL was written to the database");
};

done_testing;
