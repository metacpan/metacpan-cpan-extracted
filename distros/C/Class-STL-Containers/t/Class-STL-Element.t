# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-STL-Containers.t'

#########################

#use Test::More tests => 5;
#BEGIN { use_ok('Class::STL::Containers') };
#BEGIN { use_ok('Class::STL::Algorithms') };
#BEGIN { use_ok('Class::STL::Utilities') };

use Test;
use stl;
BEGIN { plan tests => 17 }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $e = Class::STL::Element->new(data => "hello", data_type => 'string');
ok ($e->data(), "hello", "ctor");

my $e2 = Class::STL::Element->new($e);
ok ($e2->eq($e), 1, "copy ctor");
ok ($e2->ne($e), "", "copy ctor");

my $e3 = Class::STL::Element->new(data => 100, data_type => 'numeric');
my $e4 = Class::STL::Element->new(data => 103, data_type => 'numeric');
my $e5 = Class::STL::Element->new(data => 103, data_type => 'numeric');
ok ($e3->eq($e4), "", "eq()");
ok ($e4->eq($e5), "1", "eq()");
ok ($e3->ne($e4), "1", "ne()");
ok ($e3->lt($e4), "1", "lt()");
ok ($e3->gt($e4), "", "gt()");
ok ($e3->le($e4), "1", "le()");
ok ($e3->ge($e4), "", "ge()");
ok ($e3->cmp($e4), "-1", "cmp()");
ok ($e4->cmp($e3), "1", "cmp()");
ok ($e4->cmp($e5), "0", "cmp()");

$e3->swap($e4);
ok ($e3->data(), "103", "swap()");
ok ($e4->data(), "100", "swap()");

my $e1 = MyClass->new(name => 'n1');
$e2 = MyClass2->new(name => 'n2', name2 => 'n2-2', add2 => 'mosman', zip => 2080);
$e3 = MyClass3->new(name => 'n3', name2 => 'n2-3', name3 => 'n3-3', zip => 2065, phone => '02897733', 
	state => 'SA');

ok (join(' ', $e3->name(), $e3->name2(), $e3->name3(), $e3->zip(), $e3->country(), 
	$e3->phone(), $e3->state()), "n3 n2-3 n3-3 2065 au 02897733 SA", 'inheritance');

$e4 = MyClass3->new($e3);
ok (join(' ', $e4->name(), $e4->name2(), $e4->name3(), $e4->zip(), $e4->country(), 
	$e4->phone(), $e4->state()), "n3 n2-3 n3-3 2065 au 02897733 SA", 'inheritance');


{
	package MyClass;
	use base qw(Class::STL::Element);
	use Class::STL::ClassMembers qw( name add );
	use Class::STL::ClassMembers::Constructor;
}
{
	package MyClass2;
	use base qw(MyClass);
	use Class::STL::ClassMembers qw( name2 add2 zip country ),
		Class::STL::ClassMembers::DataMember->new(name => 'country', default => 'au'),
		Class::STL::ClassMembers::DataMember->new(name => 'state', default => 'NSW',
			validate => '^(NSW|SA|WA|NT)$'),
		Class::STL::ClassMembers::DataMember->new(name => 'phone');
	use Class::STL::ClassMembers::Constructor;
}
{
	package MyClass3;
	use base qw(MyClass2);
	use Class::STL::ClassMembers qw( name3 );
	use Class::STL::ClassMembers::Constructor;
}
