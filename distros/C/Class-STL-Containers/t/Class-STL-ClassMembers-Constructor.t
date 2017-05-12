# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-STL-Containers.t'

#########################

#use Test::More tests => 5;
#BEGIN { use_ok('Class::STL::Containers') };
#BEGIN { use_ok('Class::STL::Algorithms') };
#BEGIN { use_ok('Class::STL::Utilities') };

use Test;
use stl; # qw(:containers);
BEGIN { plan tests => 10 }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Copy Constructor:
my $l1 = stl::deque(qw(1 2 3 4));
ok (join(' ', map($_->data(), $l1->to_array())), "1 2 3 4", 'copy ctor');
my $l2 = stl::deque($l1);
ok (join(' ', map($_->data(), $l2->to_array())), "1 2 3 4", 'copy ctor');

$l2->push_back($l2->factory(data => 5));
$l1->push_front($l1->factory(data => -1));
ok (join(' ', map($_->data(), $l2->to_array())), "1 2 3 4 5", 'copy ctor');
ok (join(' ', map($_->data(), $l1->to_array())), "-1 1 2 3 4", 'copy ctor');

$l2->back()->swap($l2->front());
ok (join(' ', map($_->data(), $l2->to_array())), "5 2 3 4 1", 'copy ctor');
ok (join(' ', map($_->data(), $l1->to_array())), "-1 1 2 3 4", 'copy ctor');


# Inheritance:
my $e1 = MyClass->new(name => 'n1');
my $e2 = MyClass2->new(name => 'n2', name2 => 'n2-2', add2 => 'mosman', zip => 2080);
my $e3 = MyClass3->new(name => 'n3', name2 => 'n2-3', name3 => 'n3-3', zip => 2065, phone => '02897733', 
	state => 'SA');

ok (join(' ', $e3->name(), $e3->name2(), $e3->name3(), $e3->zip(), $e3->country(), 
	$e3->phone(), $e3->state()), "n3 n2-3 n3-3 2065 au 02897733 SA", 'inheritance');

my $e4 = MyClass3->new($e3);
ok (join(' ', $e4->name(), $e4->name2(), $e4->name3(), $e4->zip(), $e4->country(), 
	$e4->phone(), $e4->state()), "n3 n2-3 n3-3 2065 au 02897733 SA", 'inheritance');

my $c2 = MyInitCtor->new();
ok (join(' ', $c2->name(), $c2->zip()), 'hello 52101', 'ctor with init list');

my $s3 = MySingleton2->new(name => 'Single', f1 => 'just', f2 => 'the one');
ok (join(' ', $s3->name(), $s3->f1(), $s3->f2()), 'Single just the one', 'singleton');

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
{
	package MyInitCtor;
	use Class::STL::ClassMembers qw(name zip);
	use Class::STL::ClassMembers::Constructor (name => 'hello', zip => '52101');
}
{
	package MySingleton2;
	use Class::STL::ClassMembers qw( name f1 f2 );
	use Class::STL::ClassMembers::Constructor (singleton => 1);
}
