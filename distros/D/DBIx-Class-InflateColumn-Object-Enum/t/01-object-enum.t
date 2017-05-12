use Test::More tests => 24;

BEGIN {
	use lib 't/lib';
	use_ok( 'DBICx::TestDatabase'); # test 1
	use_ok( 'TestDB' ); # test 2
	
}

sub _check_column { # each call to this = 7 tests
	my $col = shift;
	my $name = shift;
	ok(ref($col) =~ /^Object::Enum::/,qq($name: refereces Object::Enum));
	ok($col->can('set_red'),qq($name: has correct set method));
	ok($col->set_red,qq($name: set method contained a value));
	ok($col->is_red,qq($name: boolean return true for correct set value));
	ok($col->value eq 'red',qq($name: value access returned correct string));
	ok(!$col->unset,qq($name: unset behaved as expected));
	ok(!defined($col->value),qq($name: unset has modifed value accessor as expected));
}

my $rs;
my $db = new DBICx::TestDatabase('TestDB');

ok(ref($db) eq 'TestDB','Testing database looks good');

$rs = $db->resultset('VarcharEnumNullable')->create({id=>0});
ok(defined($rs),'VarcharEnumNullable: create returned as expected'); # test 3
ok(!defined($rs->enum),'VarcharEnumNullable: enum column is null as expected'); # test 4

$rs->enum('red');
_check_column($rs->enum,$rs->result_source->source_name); # tests 5 thru 12

undef $rs;
eval(q/$db->resultset('VarcharEnumNoneNullable')->create({id=>1})/);
ok(defined($@),'VarcharEnumNoneNullable(null enum): create with null enum failed as expected'); # test 13

# commented tests now conflict with expected behavior
#$rs = $db->resultset('VarcharEnumNoneNullable')->create({id=>2,enum=>'none'});
#ok(defined($rs),'VarcharEnumNoneNullable(invalid enum): create with invalid enum returns row as expected'); # test 14
#_check_column($rs->enum,$rs->result_source->source_name.'(invalid enum)'); # tests 15 thru 21

#undef $rs;
#$rs = $db->resultset('VarcharEnumNoneNullable')->create({id=>3,enum=>'none'});
#ok($rs->enum->value ne 'none','VarcharEnumNoneNullable(invalid enum) value return undef on valid as expected'); # test 22

undef $rs;
$rs = $db->resultset('VarcharEnumNoneNullable')->create({id=>4,enum=>'red'});
ok($rs->enum->is_red,'VarcharEnumNoneNullable(valid enum) defined correctly'); # test 23

undef $rs;
$rs = $db->resultset('NativeEnumNullable')->create({id=>5});
ok(defined($rs),'NativeEnumNullable: create returned as expected'); # test 24
ok(!defined($rs->enum),'NativeEnumNullable: enum column is null as expected'); # test 25

$rs->enum('red'); # initialize inflated object for nullable
_check_column($rs->enum,$rs->result_source->source_name); # tests 26 thru 32

undef $rs;
eval(q/$db->resultset('NativeEnumNoneNullable')->create({id=>6})/);
ok(defined($@),'NativeEnumNoneNullable(null enum): create with null enum failed as expected'); # test 33

