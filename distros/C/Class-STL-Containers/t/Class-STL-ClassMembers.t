# vim:ts=4 sw=4
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-STL-Containers.t'

#########################

use Test;
use stl;
BEGIN { plan tests => 16 }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

{
	package MyPack;
	use Class::STL::ClassMembers 
		qw(msg_text msg_type),
		Class::STL::ClassMembers::DataMember->new(
			name => 'on', validate => '^(input|output)$', default => 'input'),
		Class::STL::ClassMembers::DataMember->new(
			name => 'display_target', default => 'STDERR'),
		Class::STL::ClassMembers::DataMember->new(
			name => 'count', validate => '^\d+$', default => '100'),
		Class::STL::ClassMembers::DataMember->new(
			name => 'comment', validate => '^\w+$', default => 'hello'),
		Class::STL::ClassMembers::FunctionMember::Disable->new(qw(somfunc));
	use Class::STL::ClassMembers::Constructor;
}

my $att = MyPack->new();
ok ($att->members_print(), "comment=hello|count=100|display_target=STDERR|msg_text=NULL|msg_type=NULL|on=input", 'members_print()');
ok (join(' ', sort keys %{$att->memdata()}), "comment count display_target msg_text msg_type on", 'memdata()');

$att->count(25);
ok ($att->members_print(), "comment=hello|count=25|display_target=STDERR|msg_text=NULL|msg_type=NULL|on=input", 'put()');

ok ($att->comment(), "hello", 'get()');

ok ($att->comment($att->comment() . 'world'), "helloworld", 'put() + get()');

my $n = MyElem2->new(name => 'hello', name2 => 'world', data => '123');
ok (join(' ', $n->name(), $n->name2(), $n->data()), 'hello world 123', 'members_init()');

my $emp = MyElemEmpty->new(data_type => 'array', data => [ qw(aaa bbb ccc) ]);
ok ($emp->data_type(), "array", 'empty data member list');
ok (join(' ', @{$emp->data()}), "aaa bbb ccc", 'empty data member list');

my $s = MySingleton->new(name => 'Single', f1 => 'just', f2 => 'the one');
my $s2 = MySingleton->new();
ok (join(' ', $s2->name(), $s2->f1(), $s2->f2()), 'Single just the one', 'singleton');

my $c1 = MyClass->new(data2 => 555);
ok ($c1->data1(), "100", "DataMember");
ok ($c1->data2(), "555", "DataMember");

ok (defined($att->comment()), '1', 'undefine()');
ok (defined($att->count()), '1', 'undefine()');
$att->undefine(qw(comment));
ok (!defined($att->comment()), '1', 'undefine()');
$att->undefine(qw(comment count));
ok (!defined($att->comment()), '1', 'undefine()');
ok (!defined($att->count()), '1', 'undefine()');

{
	package MyElem;
	use base qw(Class::STL::Element);
	use Class::STL::ClassMembers qw(name);
	use Class::STL::ClassMembers::Constructor;
}
{
	package MyElem2;
	use base qw(MyElem);
	use Class::STL::ClassMembers qw(name2 name3 add1 add2 zip country );
	use Class::STL::ClassMembers::Constructor;
}
{
	package MyElemEmpty;
	use base qw(Class::STL::Element);
	use Class::STL::ClassMembers::Constructor; # ( ctor_name => 'ctor' );
}
{
	package MySingleton;
	use Class::STL::ClassMembers qw( name f1 f2 );
	use Class::STL::ClassMembers::SingletonConstructor;
}
{
	package MyClass;
	use base qw(Class::STL::Element);
	use Class::STL::ClassMembers qw(name),
		Class::STL::ClassMembers::DataMember->new(name => 'data1', default => '100',
			validate => '^(100|200|300|400)$'),
		Class::STL::ClassMembers::DataMember->new(name => 'data2');
	use Class::STL::ClassMembers::Constructor;
}
