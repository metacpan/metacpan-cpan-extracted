use strict;
use warnings;
use lib qw(lib t/lib);

use Test::More;
BEGIN {
  eval "use DBD::SQLite";
  plan skip_all => 'needs DBD::SQLite for testing' if $@;
}

use Exporter::Lite;
our @EXPORT = qw(
    setup_dbh
    create_host_table
    insert_host
);

use DBIx::Sunny;
use SQL::NamedPlaceholder qw(bind_named);

sub setup_dbh {
    my $file = shift || ':memory:';
    DBIx::Sunny->connect('dbi:SQLite:'.$file,'','',{RaiseError => 1, PrintError => 0, AutoCommit => 1});
}

# mock table
sub create_table {
    my ($dbh) = @_;
    $dbh->do(q{
        CREATE TABLE mock (
            id   integer,
            name text,
            delete_fg int(1) default 0,
            primary key ( id )
        )
    });
}

sub insert_mock {
    my ($dbh, %args) = @_;

    my ($sql, $binds) = bind_named(q[
        INSERT INTO mock (name) VALUES (:name)
    ], \%args);
    $dbh->query($sql, @$binds);
    return $dbh->last_insert_id;
}

1;
