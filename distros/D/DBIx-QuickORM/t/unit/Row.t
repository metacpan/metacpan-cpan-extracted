# Test origin: AI
use Test2::V0;

use DBI;
use DBIx::QuickORM;
use DBIx::QuickORM::Row;

ok(DBIx::QuickORM::Row->DOES('DBIx::QuickORM::Role::Row'), "The default row class consumes the row role");

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
$dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)");
my $orm = DBIx::QuickORM->new(dbh => $dbh);

my $row = $orm->insert(t => {id => 1, v => 'a'});
is(ref($row), 'DBIx::QuickORM::Row', "The ORM builds rows with it by default");
ref_is($row->orm, $orm, "holding the ORM");
is($row->table,    't',                 "the table");
is($row->row_data, {id => 1, v => 'a'}, "and the row data");

$row->set_row_data({id => 1, v => 'b'});
is($row->field('v'), 'b', "set_row_data replaces the row data");

{

    package My::Row::Plain;
    our @ISA = ('DBIx::QuickORM::Row');

    package My::Row::Init;
    our @ISA = ('DBIx::QuickORM::Row');
    sub init { $_[0]->{seen} = 1 }

    package My::Row::Own;
    use Object::HashBase qw/extra/;
    our @ISA = ('DBIx::QuickORM::Row');
}

subtest fast_bless => sub {
    ok(DBIx::QuickORM::Row->fast_bless, "The default row class is fast-blessed");
    ok(My::Row::Plain->fast_bless,      "and so is a subclass that only adds methods");
    ok(!My::Row::Init->fast_bless,      "a subclass with an init is not");
    ok(!My::Row::Own->fast_bless,       "nor one with its own HashBase new");

    my $data = {id => 1, v => 'a'};
    # Shallow: the same keys holding the same values (the ORM is compared by address).
    my $flat = sub {
        my ($r) = @_;
        return [ref($r), map { ($_ => "$r->{$_}") } sort keys %$r];
    };
    my $built = $orm->_row_builder('t')->($data);
    is($flat->($built), $flat->(DBIx::QuickORM::Row->new(row_data => $data, orm => $orm, table => 't')), "A fast-blessed row is the same as one from new");

    my $init = $orm->_row_builder('t', 'My::Row::Init')->($data);
    ok($init->{seen}, "A class with an init is built through new");
    is($orm->_row_builder('t', undef), undef, "No class: no builder, rows stay hashrefs");
};

done_testing;
