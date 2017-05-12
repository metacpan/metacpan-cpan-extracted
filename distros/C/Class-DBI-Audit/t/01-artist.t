# tests are based on those in the cdbi distribution

use strict;
use Test::More;
use Data::Dumper;
$| = 1;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : ('no_plan');
}

INIT {
	use lib 't/testlib';
	use Artist;
}

ok(Artist->can('db_Main'), 'set_db()');
is(Artist->__driver, "SQLite", "Driver set correctly");

Artist->db_Main->do('
create table artist_audit (
       id           integer NOT NULL primary key autoincrement,
       time_stamp   varchar(255), /* no datetimes in sqlite */
       parent_id    integer NOT NULL,       
       query_type   varchar(255),
       column_name  varchar(255),
       value_before blob,
       value_after  blob,
       remote_addr  varchar(255),
       remote_user  varchar(255),
       request_uri  varchar(255),
       command      varchar(255)
) ');

$ENV{REMOTE_USER} = 'jennifer_lopez123';
$ENV{REQUEST_URI}  = '/register';
$ENV{REMOTE_ADDR} = '000.000.000';

sub do_transaction(&) {
    my $sub = shift;
    Artist->db_Main->begin_work;
    $sub->();
    Artist->db_Main->commit;
}

my $id;
do_transaction {
    my $artist = Artist->create_test_artist;
    ok +$artist, "Create a test artist";
    $id = $artist->id;
};

do_transaction {
    $ENV{REMOTE_USER} = 'jenny_lopez';
    $ENV{REQUEST_URI}  = '/change_name';
    $ENV{REMOTE_ADDR} = '867.5309';

    my $artist = Artist->retrieve($id);
    is $artist->first_name, 'Jennifer', 'first name was set properly';
    $artist->first_name('Jenny');
    $artist->update;
};

do_transaction {
    $ENV{REMOTE_USER} = 'j_lo';
    $ENV{REQUEST_URI}  = '/change_name';
    $ENV{REMOTE_ADDR} = '99';

    my $artist = Artist->retrieve($id);
    $artist->first_name('J');
    $artist->last_name('Lo');
    $artist->update;
};

my $artist = Artist->retrieve($id);

my @history = $artist->column_history('first_name');
my @first_names = map $_->{value_after},  @history;
is_deeply( \@first_names, [qw(Jennifer Jenny J)], 'stored history of values' );

my @uris = map $_->{request_uri}, @history;
is_deeply (\@uris, [qw(/register /change_name /change_name)], 'stored history of uris');

my @last_names = map $_->{value_after}, $artist->column_history('last_name');
is_deeply( \@last_names, [qw(Lopez Lo)], 'stored history of another column' );

# Try changing a numeric value
do_transaction { $ENV{REMOTE_ADDR} = 23; $artist->age(23);    $artist->update; };
is $artist->age, 23, 'set age';
do_transaction { $ENV{REMOTE_ADDR} = 29; $artist->age(29);    $artist->update; };
is $artist->age, 29, 'set age';
do_transaction { $ENV{REMOTE_ADDR} = 99; $artist->age('029'); $artist->update; };
is $artist->age, 29, 'set age';
do_transaction { $ENV{REMOTE_ADDR} = 33; $artist->age(33);    $artist->update; };
is $artist->age, 33, 'set age';
my @ages = map $_->{value_after}, $artist->column_history('age');
is_deeply( \@ages, [23,29,33 ], 'no note for same numeric value');

do_transaction {
$artist->last_name(' ' x 10);
$artist->update;
};

do_transaction {
$artist->last_name('   ');
$artist->update;
};

@last_names = map $_->{value_after}, $artist->column_history('last_name');
ok @last_names==3, 'no extra audit entries for whitespace';

do_transaction {
$artist->delete;
};

my $queries = Artist->db_Main->selectcol_arrayref('select query_type from artist_audit');

my @deletes = grep /^delete/, @$queries;
is_deeply \@deletes, [qw/delete delete delete/], 'deleted and logged';

