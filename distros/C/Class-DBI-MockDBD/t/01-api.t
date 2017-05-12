#!perl

use strict;

use Data::Dumper;

use Test::More tests => 14;

use lib qw(t/);

use TestClass;

# TestClass->db_Main->trace(2);

# run query and get info
my $results = [ [qw/foo_id foo_name foo_bar/],[20,'aaaa','bbbb',],[21,'aaaa','cccc',] ];
# warn Dumper(results => $results);


# diag "[debug] manual query to objects \n";
TestClass->next_result($results);
my $dbh = TestClass->db_Main;
my $sth = $dbh->prepare('select * from notam');
my $rv = $sth->execute();
my $objects = TestClass->sth_to_objects($sth);

isa_ok($objects,'Class::DBI::Iterator');

# diag "[debug] searching \n";
TestClass->next_result($results);
$objects = TestClass->search( foo_name=>'aaaa');
isa_ok($objects,'Class::DBI::Iterator');


#diag "[debug] getting first object \n";
my $object = $objects->next();
is($object->id,20,'got object ok');
isa_ok($object,'TestClass','got object ok');

#diag "[debug] updating object  \n";
$object->foo_bar('ffff');
TestClass->next_result([['foo_id'],]);
ok($object->update(), 'updated object ok');

#diag "[debug] creating TestClass  \n";

my $new_object = TestClass->create({foo_id => 99, foo_name => 'cccc', foo_bar => 'sdasd' });

isa_ok($new_object,'TestClass');

TestClass->next_result_session([
				{
				 statement => qr/SELECT foo_id\s*FROM\s*testing123\s*WHERE\s*foo_bar\s+\=/,
				 results => [ [qw/foo_id foo_name foo_bar/],[20,'aaaa','bbbb',], ],
				 bound_params => [ qr/\w+/ ],
				},
				{
				 statement => qr/SELECT foo_id\s*FROM\s*testing123\s*WHERE\s*foo_bar\s+\=/,
				 results => [ [qw/foo_id foo_name foo_bar/],[21,'aaaa','cccc',], ],
				 bound_params => [ qr/\w+/ ],
				},
			       ]);

my $b_objects = TestClass->search(foo_bar => 'bbbb');

# warn "b objects : ", $b_objects->count, "\n";

my $b_object = $b_objects->first;

is($b_object->id, 20, 'got object from first result set ok');

my $c_objects = TestClass->search(foo_bar => 'cccc');

# warn "c objects : ", $c_objects->count, "\n";

my $c_object = $c_objects->first;

is($c_object->id, 21, 'got object from second result set ok');

TestClass->next_result_session([
				{
				 statement => qr/SELECT foo_id\s*FROM\s*testing123\s*WHERE\s*foo_bar\s+\=/,
				 results => [ [qw/foo_id foo_name foo_bar/],[20,'aaaa','bbbb',], ],
				 bound_params => [ qr/\w+/ ],
				},
				{
				 statement => qr/SELECT foo_id\s*FROM\s*testing123\s*WHERE\s*foo_bar\s+\=/,
				 results => [ [qw/foo_id foo_name foo_bar/], ],
				 bound_params => [ qr/\w+/ ],
				},
				{
				 statement => qr/SELECT foo_id\s*FROM\s*testing123\s*WHERE\s*foo_bar\s+\=/,
				 results => [ [qw/foo_id foo_name foo_bar/],[21,'aaaa','cccc',], ],
				 bound_params => [ qr/\w+/ ],
				},
			       ]);

my $objects1 = TestClass->search(foo_bar => 'bbbb');
my $objects2 = TestClass->search(foo_bar => 'cccc');
my $objects3 = TestClass->search(foo_bar => 'dddd');

isa_ok($objects1, 'Class::DBI::Iterator','first normal search ok');
isa_ok($objects2, 'Class::DBI::Iterator','2nd empty search ok');
isa_ok($objects3, 'Class::DBI::Iterator','3rd normal search ok');

is($objects1->count(), 1, 'normal result count correct'); 
is($objects2->count(), 0, 'empty result count correct'); 
is($objects3->count(), 1, 'normal result count correct'); 
