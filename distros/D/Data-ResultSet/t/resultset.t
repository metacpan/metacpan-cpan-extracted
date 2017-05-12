use Test::More tests => 27;
use Test::Exception;
use Test::MockObject;

BEGIN {
	use_ok('Data::ResultSet');
}

# Make one
{
	package My::ResultSet;
	use base qw( Data::ResultSet );
	__PACKAGE__->make_wrappers_for_all( 'is_ok' );
	__PACKAGE__->make_wrappers_for_has( 'is_ok' );
	__PACKAGE__->make_wrappers_for_get( 'is_ok' );
	__PACKAGE__->make_wrappers_for_get_not( 'is_ok' );
}

my $rs = My::ResultSet->new();
isa_ok( $rs, 'My::ResultSet' );
isa_ok( $rs, 'Data::ResultSet' );
is( $rs->count, 0, 'Contains zero objects');

my $good_obj = Test::MockObject->new()->set_true('is_ok');

lives_ok { $rs->add( $good_obj) } 'Added an object to resultset';
is( $rs->count, 1, 'Contains one object');
is( $rs->[0], $good_obj, '... successfully');

ok( $rs->all_ok(), '->all_ok() returns true');
ok( $rs->has_ok(), '->has_ok() returns true');
is_deeply( [ $rs->contents() ], [ $good_obj ], '->contents() returns good object');
is_deeply( [ $rs->get_ok() ], [ $good_obj ], '->get_ok() returns good object');
is_deeply( [ $rs->get_not_ok() ], [ ], '->get_not_ok() returns empty list');

my $bad_obj = Test::MockObject->new()->set_false('is_ok');

lives_ok { $rs->add( $bad_obj) } 'Added another object to resultset';
is( $rs->[1], $bad_obj, '... successfully');
is( $rs->count, 2, 'Contains two objects');

ok( ! $rs->all_ok(), '->all_ok() returns false');
ok( $rs->has_ok(), '->has_ok() returns true');
is_deeply( [ $rs->contents() ], [ $good_obj, $bad_obj ], '->contents() returns good and bad objects');
is_deeply( [ $rs->get_ok() ], [ $good_obj ], '->get_ok() returns good object');
is_deeply( [ $rs->get_not_ok() ], [ $bad_obj ], '->get_not_ok() returns empty list');

# Clear and try with all bad objects
ok( $rs->clear(), '->clear() returned true');
is( scalar @{$rs}, 0, '... now it is empty'); 
for(1..3) {
	$rs->add( Test::MockObject->new->set_false('is_ok') );
}
is( $rs->count, 3, 'rs has three objects'); 
ok( ! $rs->all_ok(), '->all_ok() returns false');
ok( ! $rs->has_ok(), '->has_ok() returns false');
is_deeply( [ $rs->get_ok() ], [ ], '->get_ok() returns empty list');
is_deeply( [ $rs->get_not_ok() ], [ $rs->contents ], '->get_not_ok() returns contents of resultset');
