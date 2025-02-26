use 5.014;
use warnings;

# Create the DBO (2 tests)
use lib '.';
use Test::DBO Sponge => 'Sponge', tests => 18;

# DBO-only Subclass
@Only::DBO::ISA = qw(DBIx::DBO);

ok my $dbo = Only::DBO->connect('DBI:Sponge:'), 'Connect to Sponge' or die $DBI::errstr;
isa_ok $dbo, 'Only::DBO', '$dbo';
is $dbo->{dbd_class}, 'DBIx::DBO::DBD::Sponge', 'DBD class is DBIx::DBO::DBD::Sponge';

my $quoted = $dbo->{dbd_class}->_qi($dbo, $Test::DBO::test_db, $Test::DBO::test_tbl);
is $quoted, qq{"$Test::DBO::test_db"."$Test::DBO::test_tbl"}, 'Only::DBO Method _qi';

# Empty Subclasses
sub SubClass::dbd_class { 'SubClass::DBD' }
sub SubClass::table_class { 'SubClass::Table' }
sub SubClass::query_class { 'SubClass::Query' }
sub SubClass::row_class   { 'SubClass::Row' }
@SubClass::ISA = qw(DBIx::DBO);
@SubClass::DBD::ISA = qw(DBIx::DBO::DBD);
@SubClass::Table::ISA = qw(DBIx::DBO::Table);
@SubClass::Query::ISA = qw(DBIx::DBO::Query);
@SubClass::Row::ISA = qw(DBIx::DBO::Row);
BEGIN { # Fake existence of package
    package # Hide from PAUSE
    SubClass::DBD::Sponge;
}

$dbo = SubClass->connect('DBI:Sponge:') or die $DBI::errstr;
isa_ok $dbo, 'SubClass', '$dbo';
is $dbo->{dbd_class}, 'SubClass::DBD::Sponge', 'DBD class is SubClass::DBD::Sponge';

is_deeply mro::get_linear_isa($dbo->{dbd_class}),
    [qw(SubClass::DBD::Sponge SubClass::DBD DBIx::DBO::DBD::Sponge DBIx::DBO::DBD)], $dbo->{dbd_class}.' uses C3 mro';

isa_ok my $t = $dbo->table($Test::DBO::test_tbl), 'SubClass::Table', '$t';
isa_ok my $q = $dbo->query($t), 'SubClass::Query', '$q';
isa_ok my $r = $q->row, 'SubClass::Row', '$r';

# Empty Table Subclass
@MyTable::ISA = qw(DBIx::DBO::Table);
isa_ok $t = MyTable->new($dbo, $t), 'MyTable', '$t';

# Empty Query Subclass
@MyQuery::ISA = qw(DBIx::DBO::Query);
isa_ok $q = MyQuery->new($dbo, $t), 'MyQuery', '$q';

# Empty Row Subclass
@MyRow::ISA = qw(DBIx::DBO::Row);
isa_ok $r = MyRow->new($dbo, $t), 'MyRow', '$r';

# Create a Query and Row class for a table
{
    package # hide from PAUSE
        My::Query;
    use base 'SubClass::Query';
    sub row_class { 'My::Row' }
    sub new {
        my($class, $dbo) = @_;
        my($me, $t1) = $class->SUPER::new($dbo, $Test::DBO::test_tbl);
        my $t2 = $me->join_table($Test::DBO::test_tbl, 'JOIN');
        $me->join_on($t2, $t1 ** 'id', '=', $t2 ** 'id');
        return $me;
    }
}
{
    package # hide from PAUSE
        My::Row;
    use base 'SubClass::Row';
    sub query_class { 'My::Query' }
}

sub build_from {
    my($obj, $build_data) = @_;
    return $obj->dbo->{dbd_class}->_build_from($obj, $build_data);
}
$quoted = $dbo->{dbd_class}->_qi($dbo, $Test::DBO::test_tbl);
my $from = qq{$quoted "t1" JOIN $quoted "t2" ON "t1"."id" = "t2"."id"};

$q = My::Query->new($dbo);
isa_ok $q, 'My::Query', '$q';
is build_from($q, $q->{build_data}), $from,
    'Subclassed Query represents the table join automatically';

$r = My::Row->new($dbo);
isa_ok $r, 'My::Row', '$r';
is build_from($r, $$r->{build_data}), $from,
    'Subclassed Row represents the table join automatically';

$r = $q->row;
isa_ok $r, 'My::Row', '$q->row';

