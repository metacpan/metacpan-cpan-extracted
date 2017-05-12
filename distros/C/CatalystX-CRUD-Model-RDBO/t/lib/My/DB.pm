package My::DB;
use strict;
use warnings;
use base qw( Rose::DB );
use Carp;
use Rose::DBx::TestDB;

# create a temp db
my $db = Rose::DBx::TestDB->new;

{
    my $dbh = $db->dbh;

    # create a schema to match this class
    $dbh->do(
        "create table foos 
            ( id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(16) );"
    );

    $dbh->do(
        "create table bars 
            ( id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(16) );"
    );

    $dbh->do(
        "create table foo_bars 
            ( foo_id INTEGER references foos(id), bar_id INTEGER references bars(id) );"
    );

    # create some data
    $dbh->do("insert into foos (name) values ('blue');");
    $dbh->do("insert into bars (name) values ('green');");
    $dbh->do("insert into bars (name) values ('red');");
    $dbh->do("insert into foo_bars (foo_id, bar_id) values (1,1);");

    # double check
    my $sth = $dbh->prepare("SELECT * FROM foos");
    $sth->execute;
    croak "bad seed data in sqlite"
        unless $sth->fetchall_arrayref->[0]->[0] == 1;

    $sth = undef;    # http://rt.cpan.org/Ticket/Display.html?id=22688
                     # does not seem to work.

}

sub new {
    return $db;
}

1;
