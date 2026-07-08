use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# The pre_table and links hooks that 'autoname table' / 'autoname link' install
# must return the seed value they mutate (the table hashref / the links
# arrayref), because the autofill hook pipeline threads each callback's return
# value into the next callback under the same seed key. A hook registered after
# the autoname one must therefore still receive the real structure, not the
# name string or undef.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

use DBIx::QuickORM;

my $dir   = tempdir(CLEANUP => 1);
my $flat  = "$dir/flat.sqlite";     # no foreign keys: safe to rename tables
my $fkeys = "$dir/fkeys.sqlite";    # foreign keys: exercises the links hook

{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$flat", '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE alpha (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do('CREATE TABLE beta  (id INTEGER PRIMARY KEY, label TEXT)');
    $dbh->disconnect;

    $dbh = DBI->connect("dbi:SQLite:dbname=$fkeys", '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do('CREATE TABLE items (item_id INTEGER PRIMARY KEY, owner_id INTEGER REFERENCES users(user_id))');
    $dbh->disconnect;
}

my (@table_ref_seen, @links_ref_seen);

# A pre_table hook chained after 'autoname table' must receive the table hashref.
orm table_orm => sub {
    db mydb => sub {
        dialect 'SQLite';
        db_name $flat;
    };

    autofill sub {
        autoname table => sub {
            my %p = @_;
            return "t_$p{name}";
        };
        autohook pre_table => sub {
            my %p = @_;
            push @table_ref_seen => ref($p{table});
            return $p{table};
        };
    };
};

orm('table_orm')->connect;

ok(@table_ref_seen > 0, "the second pre_table hook ran");
is([grep { $_ ne 'HASH' } @table_ref_seen], [], "every pre_table hook after autoname received a hashref, not a name string");

# A links hook chained after 'autoname link' must receive the links arrayref.
# (No table rename here, so foreign-key links still resolve.)
orm link_orm => sub {
    db mydb2 => sub {
        dialect 'SQLite';
        db_name $fkeys;
    };

    autofill sub {
        autoname link => sub {
            my %p = @_;
            return;    # keep default names; we only care about the threading
        };
        autohook links => sub {
            my %p = @_;
            push @links_ref_seen => ref($p{links});
            return $p{links};
        };
    };
};

orm('link_orm')->connect;

ok(@links_ref_seen > 0, "the second links hook ran");
is([grep { $_ ne 'ARRAY' } @links_ref_seen], [], "every links hook after autoname received an arrayref, not undef");

done_testing;
