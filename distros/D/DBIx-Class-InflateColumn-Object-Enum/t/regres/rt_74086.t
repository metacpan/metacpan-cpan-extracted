use Test::More 'no_plan';

BEGIN {
    use lib 't/lib';
    use_ok 'DBICx::TestDatabase';
    use_ok 'TestDB';
    use_ok 'Try::Tiny';
}

my $db = DBICx::TestDatabase->new('TestDB');

isa_ok $db, 'TestDB';

my $rs = $db->resultset('VarcharEnumNoneNullable')
            ->create({id => 1, enum => 'red'});

ok defined($rs) && $rs, 'got a resultset'
    or diag "ResultSet: $rs";

try {
    $rs->enum('pink');
    $rs->enum; # trigger inflator
} catch {
    ok 1, "Throws an exception: $_"
} finally {
    ok 0, 'Does not throw an exception' unless @_;
}

