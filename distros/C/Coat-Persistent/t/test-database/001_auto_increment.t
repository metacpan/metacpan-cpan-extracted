# This test is here to validate that C::P works without DBIx::Sequence
use Test::More;

{
    package Book;
    use Coat;
    use Coat::Persistent table_name => 'books';
    use Coat::Persistent::Types;

    has_p 'name' => (
        isa => 'Str',
    );

    has_p 'created_at' => (
        isa => 'Class::Date',
        store_as => 'DateTime',
    );

    sub BUILD {
        my ($self) = @_;
        $self->created_at(time());
    }
}

my $dbh;

# init
eval "use Test::Database";
plan skip_all => "Test::Database is needed" if $@;


# MySQL tests
my ($mysql) = Test::Database->handles( 'mysql' );
plan skip_all => "No MySQL database handle available" 
    unless defined $mysql;

plan tests => 10;
$dbh = $mysql->dbh;
Coat::Persistent->disable_internal_sequence_engine();
Coat::Persistent->set_dbh(mysql => $dbh);

eval { $dbh->do("CREATE TABLE books (
    id int(11) not null auto_increment, 
    name varchar(30) not null default '',
    created_at datetime not null,
    primary key (id)
)") };


my $b = Book->new(name => 'Ubik');
ok($b->save, 'save works');
is(1, $b->id, 'first object inserted got id 1');
ok($b->created_at, 'field created_at is set');
ok($b->created_at->epoch, 'created_at is a Class::Date object: '.$b->created_at->epoch);

my $c = Book->create(name => 'Blade Runner');
is(2, $c->id, 'second object inserted got id 2');

$dbh->do('DROP TABLE books');

# SQLite tests

my ($sqlite) = Test::Database->handles( 'SQLite' );
skip "No SQLite database handle available", 5 unless defined $sqlite;

$dbh = $sqlite->dbh;
Coat::Persistent->disable_internal_sequence_engine();
Coat::Persistent->set_dbh(sqlite => $dbh);

# Fixtures
eval { $dbh->do("CREATE TABLE books (
    id INTEGER PRIMARY KEY, 
    name varchar(30) ,
    created_at TIMESTAMP
)") };

# tests
$b = Book->new(name => 'Ubik');
ok($b->save, 'save works');
is(1, $b->id, 'first object inserted got id 1');
ok($b->created_at, 'field created_at is set');
ok($b->created_at->epoch, 'created_at is a Class::Date object: '.$b->created_at->epoch);

$c = Book->create(name => 'Blade Runner');
is(2, $c->id, 'second object inserted got id 2');

# cleanup
$dbh->do('DROP TABLE books');
