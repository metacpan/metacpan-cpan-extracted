use Test::More tests => 783;
use Basset::Object;
package Basset::Object;
{		Test::More::ok(1, "uses strict");
		Test::More::ok(1, "uses warnings");
};
{#line 307 add_attr
sub add_test_accessor {
	my $pkg = shift;
	my $attr = shift;
	my $prop = shift;
	my $extra = shift;

	no strict 'refs';

	return sub   {
				my $self = shift;
				return $self->error("Not a class attribute", "BO-08") unless ref $self;
				$extra;
		};
}

Test::More::ok(\&Basset::Object::test_accessor, "Added test accessor");

my $o = Basset::Object->new();
Test::More::ok($o, "Object created");

Test::More::ok(Basset::Object->add_attr('test_attribute1'), "Added attribute for _accessor");
Test::More::ok(Basset::Object->add_attr('test_attribute1'), "Re-added attribute for _accessor");
Test::More::ok($o->can('test_attribute1'), "Object sees attribute");
Test::More::ok(Basset::Object->can('test_attribute1'), "Class sees attribute");

Test::More::is($o->test_attribute1('testval1'), 'testval1', "Method test_attribute1 mutates");
Test::More::is($o->test_attribute1(), 'testval1', "Method test_attribute1 accesses");
Test::More::is($o->test_attribute1(undef), undef, "Method test_attribute1 deletes");

Test::More::is(scalar Basset::Object->test_attribute1('testval17'), undef, "Class fails to mutate");
Test::More::is(scalar Basset::Object->test_attribute1(), undef, "Class fails to access");
Test::More::is(scalar Basset::Object->test_attribute1(undef), undef, "Class fails to delete");

Test::More::ok(Basset::Object->add_attr(['test_attribute2', 'add_test_accessor', 'excess']), "Added attribute for test_accessor");
Test::More::ok(Basset::Object->add_attr(['test_attribute2', 'add_test_accessor', 'excess']), "Re-added attribute for test_accessor");
Test::More::ok($o->can('test_attribute2'), "Object sees attribute");
Test::More::ok(Basset::Object->can('test_attribute2'), "Class sees attribute");

Test::More::is($o->test_attribute2('testval2'), 'excess', "Method test_attribute2 mutates");
Test::More::is($o->test_attribute2(), 'excess', "Method test_attribute2 accesses");
Test::More::is($o->test_attribute2(undef), 'excess', "Method test_attribute2 deletes");

Test::More::is(scalar Basset::Object->test_attribute2('testval18'), undef, "Class fails to mutate");
Test::More::is(scalar Basset::Object->test_attribute2(), undef, "Class fails to access");
Test::More::is(scalar Basset::Object->test_attribute2(undef), undef, "Class fails to delete");

Test::More::ok(Basset::Object->add_attr('test_attribute3', 'static'), "Added static attribute");
Test::More::ok($o->can('test_attribute3'), "Object sees attribute");
Test::More::ok(Basset::Object->can('test_attribute3'), "Class sees attribute");

Test::More::is($o->test_attribute3('status'), 'status', "Method test_attribute3 mutates");
Test::More::is($o->test_attribute3(), 'status', "Method test_attribute3 accesses");
Test::More::is($o->test_attribute3(undef), undef, "Method test_attribute3 deletes");

Test::More::is(scalar Basset::Object->test_attribute3('testval19'), undef, "Class fails to mutate");
Test::More::is(scalar Basset::Object->test_attribute3(), undef, "Class fails to access");
Test::More::is(scalar Basset::Object->test_attribute3(undef), undef, "Class fails to delete");

Test::More::ok(Basset::Object->add_attr(['test_attribute4', '_isa_regex_accessor', '^\d+$', 'Numbers only', 'test code']), "Added numeric only regex attribute");
Test::More::ok($o->can('test_attribute4'), "Object sees attribute");
Test::More::ok(Basset::Object->can('test_attribute4'), "Class sees attribute");

Test::More::isnt(scalar $o->test_attribute4('foo'), 'foo', "Method test_attribute4 fails to set non-numeric");
Test::More::is($o->error, "Numbers only", "Proper object error message");
Test::More::is($o->errcode, "test code", "Proper object error code");
Test::More::isnt(scalar $o->test_attribute4('1234567890a'), '1234567890a', "Method test_attribute4 fails to set non-numeric");
Test::More::is($o->error, "Numbers only", "Proper object error message");
Test::More::is($o->errcode, "test code", "Proper object error code");
Test::More::isnt(scalar $o->test_attribute4('a1234567890'), 'a1234567890', "Method test_attribute4 fails to set non-numeric");
Test::More::is($o->error, "Numbers only", "Proper object error message");
Test::More::is($o->errcode, "test code", "Proper object error code");
Test::More::isnt(scalar $o->test_attribute4('123456a7890'), '123456a7890', "Method test_attribute4 fails to set non-numeric");
Test::More::is($o->error, "Numbers only", "Proper object error message");
Test::More::is($o->errcode, "test code", "Proper object error code");
Test::More::is(scalar $o->test_attribute4('12345'), '12345', "Method test_attribute4 mutates");
Test::More::is(scalar $o->test_attribute4(), '12345', "Method test_attribute4 accesses");
Test::More::is(scalar $o->test_attribute4(undef), undef, "Method test_attribute4 deletes");

Test::More::is(scalar Basset::Object->test_attribute4('testval20'), undef, "Class fails to mutate");
Test::More::is(scalar Basset::Object->test_attribute4(), undef, "Class fails to access");
Test::More::is(scalar Basset::Object->test_attribute4(undef), undef, "Class fails to delete");

Test::More::ok(Basset::Object->add_attr(['test_attribute5', '_isa_regex_accessor', 'abcD', 'Must contain abcD', 'test code2']), "Added abcD only regex attribute");
Test::More::ok($o->can('test_attribute5'), "Object sees attribute");
Test::More::ok(Basset::Object->can('test_attribute5'), "Class sees attribute");

Test::More::isnt(scalar $o->test_attribute5('foo'), 'foo', "Method test_attribute4 fails to set non-abcD");
Test::More::is($o->error, "Must contain abcD", "Proper object error message");
Test::More::is($o->errcode, "test code2", "Proper object error code");
Test::More::isnt(scalar $o->test_attribute5('abc'), 'abc', "Method test_attribute4 fails to set non-abcD");
Test::More::is($o->error, "Must contain abcD", "Proper object error message");
Test::More::is($o->errcode, "test code2", "Proper object error code");
Test::More::isnt(scalar $o->test_attribute5('bcD'), 'bcD', "Method test_attribute4 fails to set non-abcD");
Test::More::is($o->error, "Must contain abcD", "Proper object error message");
Test::More::is($o->errcode, "test code2", "Proper object error code");
Test::More::isnt(scalar $o->test_attribute5('abD'), 'abD', "Method test_attribute4 fails to set non-abcD");
Test::More::is($o->error, "Must contain abcD", "Proper object error message");
Test::More::is($o->errcode, "test code2", "Proper object error code");
Test::More::is(scalar $o->test_attribute5('abcD'), 'abcD', "Method test_attribute5 mutates");
Test::More::is(scalar $o->test_attribute5('abcDE'), 'abcDE', "Method test_attribute5 mutates");
Test::More::is(scalar $o->test_attribute5('1abcD'), '1abcD', "Method test_attribute5 mutates");
Test::More::is(scalar $o->test_attribute5('zabcDz'), 'zabcDz', "Method test_attribute5 mutates");
Test::More::is(scalar $o->test_attribute5(), 'zabcDz', "Method test_attribute5 accesses");
Test::More::is(scalar $o->test_attribute5(undef), undef, "Method test_attribute5 deletes");

Test::More::is(scalar Basset::Object->test_attribute5('testval20'), undef, "Class fails to mutate");
Test::More::is(scalar Basset::Object->test_attribute5(), undef, "Class fails to access");
Test::More::is(scalar Basset::Object->test_attribute5(undef), undef, "Class fails to delete");

package Basset::Test::Testing::Basset::Object::add_attr::Subclass1;
our @ISA = qw(Basset::Object);

my $sub_class = "Basset::Test::Testing::Basset::Object::add_attr::Subclass1";

my $so = $sub_class->new();

Test::More::ok(scalar $sub_class->add_attr(['secret', '_isa_private_accessor']), 'added secret accessor');
Test::More::ok($so->can('secret'), "Object sees secret attribute");
Test::More::is($so->secret('foobar'), 'foobar', 'Object sets secret attribute');
Test::More::is($so->secret(), 'foobar', 'Object sees secret attribute');

package Basset::Object;

Test::More::is(scalar $so->secret(), undef, 'Object cannot see secret attribute outside');
Test::More::is($so->errcode, 'BO-27', 'proper error code');
};
{#line 464 add_class_attr
my $o = Basset::Object->new();
Test::More::ok($o, "Object created");

Test::More::ok(Basset::Object->add_class_attr('test_class_attribute_1'), "Added test class attribute");
Test::More::ok(Basset::Object->add_class_attr('test_class_attribute_1'), "Re-added test class attribute");
Test::More::ok($o->can("test_class_attribute_1"), "object can see class attribute");
Test::More::ok(Basset::Object->can("test_class_attribute_1"), "class can see class attribute");

Test::More::is(Basset::Object->test_class_attribute_1('test value 1'), 'test value 1', 'class method call mutates');
Test::More::is(Basset::Object->test_class_attribute_1(), 'test value 1', 'class method call accesses');
Test::More::is(Basset::Object->test_class_attribute_1(undef), undef, 'class method call deletes');

Test::More::is($o->test_class_attribute_1('test value 2'), 'test value 2', 'object method call mutates');
Test::More::is($o->test_class_attribute_1(), 'test value 2', 'object method call accesses');
Test::More::is($o->test_class_attribute_1(undef), undef, 'object method call deletes');

Test::More::ok(Basset::Object->add_class_attr('test_class_attribute_2', 14), "Added test class attribute 2");
Test::More::ok($o->can("test_class_attribute_2"), "object can see class attribute");
Test::More::ok(Basset::Object->can("test_class_attribute_2"), "class can see class attribute");

Test::More::is(Basset::Object->test_class_attribute_2(), 14, "Class has default arg");
Test::More::is(Basset::Object->test_class_attribute_2(), 14, "Object has default arg");

Test::More::is(Basset::Object->test_class_attribute_2('test value 3'), 'test value 3', 'class method call mutates');
Test::More::is(Basset::Object->test_class_attribute_2(), 'test value 3', 'class method call accesses');
Test::More::is(Basset::Object->test_class_attribute_2(undef), undef, 'class method call deletes');

Test::More::is($o->test_class_attribute_1('test value 4'), 'test value 4', 'class method call mutates');
Test::More::is($o->test_class_attribute_1(), 'test value 4', 'object method call accesses');
Test::More::is($o->test_class_attribute_1(undef), undef, 'object method call deletes');

package Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1;
our @ISA = qw(Basset::Object);

package Basset::Object;

my $so = Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->new();
Test::More::ok($so, "Sub-Object created");

Test::More::is(scalar Basset::Object->test_class_attribute_1("newer test val"), "newer test val", "trickle method class re-mutates");

Test::More::is(scalar $so->test_class_attribute_1(), "newer test val", "trickle method sub-object accesses super");

Test::More::is(scalar $so->test_class_attribute_1("testval3"), "testval3", "trickle method sub-object mutates");
Test::More::is(scalar $so->test_class_attribute_1(), "testval3", "trickle method sub-object accesses");
Test::More::is(scalar $so->test_class_attribute_1(undef), undef, "trickle method sub-object deletes");

Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->test_class_attribute_1("testval4"), "testval4", "trickle method class mutates");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->test_class_attribute_1(), "testval4", "trickle method subclass accesses");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->test_class_attribute_1(undef), undef, "trickle method subclass deletes");

Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->test_class_attribute_1("sub value"), "sub value", "Subclass re-mutates");
Test::More::is(scalar Basset::Object->test_class_attribute_1(), "sub value", "Super class affected on access");

Test::More::is(scalar Basset::Object->test_class_attribute_1("super value"), "super value", "Super class re-mutates");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->test_class_attribute_1(), "super value", "Sub class affected on access");

package Basset::Test::Testing::Basset::Object::add_class_attr::Subclass5;
our @ISA = qw(Basset::Object);

sub conf {
	return undef;
};

package Basset::Object;

{

	local $@ = undef;

	eval {
		Basset::Test::Testing::Basset::Object::add_class_attr::Subclass5->add_class_attr('test_class_attr');
	};

	Test::More::like($@, qr/^Conf file error :/, 'could not add class attr w/o conf file');
}

my $conf = Basset::Object->conf();
$conf->{'Basset::Object'}->{'_test_attribute'} = 'test value';

Test::More::ok(Basset::Object->add_class_attr('_test_attribute'), 'added test attribute');
Test::More::is(Basset::Object->_test_attribute, 'test value', 'populated with value from conf fiel');
};
{#line 763 add_trickle_class_attr
my $o = Basset::Object->new();
Test::More::ok($o, "Object created");

Test::More::ok(Basset::Object->add_trickle_class_attr('trick_attr1'), "Added test trickle class attribute");
Test::More::ok(Basset::Object->add_trickle_class_attr('trick_attr1'), "Re-added test trickle class attribute");
Test::More::ok($o->can("trick_attr1"), "object can see trickle class attribute");
Test::More::ok(Basset::Object->can("trick_attr1"), "class can see trickle class attribute");

package Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1;
our @ISA = qw(Basset::Object);

package Basset::Object;

my $so = Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->new();
Test::More::ok($so, "Sub-Object created");

Test::More::is(scalar $o->trick_attr1("testval1"), "testval1", "trickle method object mutates");
Test::More::is(scalar $o->trick_attr1(), "testval1", "trickle method object accesses");
Test::More::is(scalar $o->trick_attr1(undef), undef, "trickle method object deletes");

Test::More::is(scalar Basset::Object->trick_attr1("testval2"), "testval2", "trickle method class mutates");
Test::More::is(scalar Basset::Object->trick_attr1(), "testval2", "trickle method class accesses");
Test::More::is(scalar Basset::Object->trick_attr1(undef), undef, "trickle method class deletes");
Test::More::is(scalar Basset::Object->trick_attr1("newer test val"), "newer test val", "trickle method class re-mutates");

Test::More::is(scalar $so->trick_attr1(), "newer test val", "trickle method sub-object accesses super");

Test::More::is(scalar $so->trick_attr1("testval3"), "testval3", "trickle method sub-object mutates");
Test::More::is(scalar $so->trick_attr1(), "testval3", "trickle method sub-object accesses");
Test::More::is(scalar $so->trick_attr1(undef), undef, "trickle method sub-object deletes");

Test::More::is(scalar Basset::Object->trick_attr1("supertestval"), "supertestval", "super trickle method class mutates");
Test::More::is(Basset::Object->trick_attr1(), "supertestval", "trickle method class accesses");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->trick_attr1("testval4"), "testval4", "trickle method class mutates");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->trick_attr1(), "testval4", "trickle method subclass accesses");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->trick_attr1(undef), undef, "trickle method subclass deletes");
Test::More::is(Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->trick_attr1(), undef, "subclass still sees undef as value");

Test::More::is(scalar Basset::Object->trick_attr1("super value"), "super value", "Super class re-mutates");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->trick_attr1("sub value"), "sub value", "Subclass re-mutates");

Test::More::is(scalar Basset::Object->trick_attr1(), "super value", "Super class unaffected on access");
Test::More::is(scalar Basset::Object->trick_attr1("new super value"), "new super value", "Super class re-mutates");
Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_class_attr::Subclass1->trick_attr1(), "sub value", "Sub class unaffected on access");

package Basset::Test::Testing::Basset::Object::add_trickle_class_attr::Subclass5;
our @ISA = qw(Basset::Object);

sub conf {
	return undef;
};

package Basset::Object;

{
	local $@ = undef;
	eval {
		Basset::Test::Testing::Basset::Object::add_trickle_class_attr::Subclass5->add_class_attr('test_trickle_attr');
	};
	Test::More::like($@, qr/^Conf file error :/, 'could not add trickle class attr w/o conf file');
}
};
{#line 870 add_default_attr
package Basset::Test::Testing::Basset::Object::add_default_class_attr::subclass;
our @ISA = qw(Basset::Object);

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::add_default_class_attr::subclass->add_default_class_attr('some_test_attr'), "Added default class attribute");
Test::More::ok(Basset::Test::Testing::Basset::Object::add_default_class_attr::subclass->add_default_class_attr('some_test_attr'), "Re-added default class attribute");

package Basset::Test::Testing::Basset::Object::add_default_class_attr::Subclass5;
our @ISA = qw(Basset::Object);

sub conf {
	return undef;
};

package Basset::Object;

{
	local $@ = undef;
	eval {
		Basset::Test::Testing::Basset::Object::add_default_class_attr::Subclass5->add_class_attr('test_default_attr');
	};
	Test::More::like($@, qr/^Conf file error :/, 'could not add default class attr w/o conf file');
}
};
{#line 935 attributes
package Basset::Test::Testing::Basset::Object::attributes::Subclass1;
our @ISA = qw(Basset::Object);
my $subclass = "Basset::Test::Testing::Basset::Object::attributes::Subclass1";

$subclass->add_attr('foo');
$subclass->add_attr('bar');
$subclass->add_class_attr('baz');
$subclass->add_trickle_class_attr('trick');

Test::More::is(ref $subclass->attributes('instance'), 'ARRAY', 'instance attributes is array');
Test::More::is(ref $subclass->attributes('class'), 'ARRAY', 'class attributes is array');
Test::More::is(ref $subclass->attributes('both'), 'ARRAY', 'both attributes is array');
Test::More::is(scalar $subclass->attributes('invalid'), undef, 'non token attributes is error');
Test::More::is($subclass->errcode, 'BO-37', 'proper error code');

my $instance = { map {$_ => 1} @{$subclass->attributes} };
Test::More::is($instance->{'foo'}, 1, 'foo is instance attribute from anon');
Test::More::is($instance->{'bar'}, 1, 'bar is instance attribute from anon');
Test::More::is($instance->{'baz'}, undef, 'baz is not instance attribute from anon');
Test::More::is($instance->{'trick'}, undef, 'trick is not instance attribute from anon');

my $instance_ex = { map {$_ => 1} @{$subclass->attributes('instance')} };
Test::More::is($instance_ex->{'foo'}, 1, 'foo is instance attribute from explicit');
Test::More::is($instance_ex->{'bar'}, 1, 'bar is instance attribute from explicit');
Test::More::is($instance_ex->{'baz'}, undef, 'baz is not instance attribute from explicit');
Test::More::is($instance_ex->{'trick'}, undef, 'trick is not instance attribute from explicit');

my $both = { map {$_ => 1} @{$subclass->attributes('both')} };
Test::More::is($both->{'foo'}, 1, 'foo is instance attribute from both');
Test::More::is($both->{'bar'}, 1, 'bar is instance attribute from both');
Test::More::is($both->{'baz'}, 1, 'baz is class attribute from both');
Test::More::is($both->{'trick'}, 1, 'trick is class attribute from both');

my $class = { map {$_ => 1} @{$subclass->attributes('class')} };
Test::More::is($class->{'foo'}, undef, 'foo is not instance attribute from class');
Test::More::is($class->{'bar'}, undef, 'bar is not instance attribute from class');
Test::More::is($class->{'baz'}, 1, 'baz is class attribute from both');
Test::More::is($class->{'trick'}, 1, 'trick is class attribute from class');
};
{#line 1007 is_attribute
package Basset::Test::Testing::Basset::Object::is_attribute::Subclass1;
our @ISA = qw(Basset::Object);
my $subclass = "Basset::Test::Testing::Basset::Object::is_attribute::Subclass1";

$subclass->add_attr('ins1');
$subclass->add_attr('ins2');
$subclass->add_class_attr('class');
$subclass->add_trickle_class_attr('trick');

Test::More::ok($subclass->is_attribute('ins1') != 0, 'ins1 is instance by default');
Test::More::ok($subclass->is_attribute('ins2') != 0, 'ins2 is instance by default');

Test::More::ok($subclass->is_attribute('ins1', 'instance') != 0, 'ins1 is instance by explicitly');
Test::More::ok($subclass->is_attribute('ins2', 'instance') != 0, 'ins2 is instance by explicitly');

Test::More::ok($subclass->is_attribute('class') == 0, 'class is not attribute by default');
Test::More::ok($subclass->is_attribute('class', 'class') != 0, 'class is class attribute by default');

Test::More::ok($subclass->is_attribute('trick') == 0, 'trick is not attribute by default');
Test::More::ok($subclass->is_attribute('trick', 'class') != 0, 'trick is class attribute by default');

Test::More::ok($subclass->is_attribute('ins1', 'both') != 0, 'ins1 is instance by both');
Test::More::ok($subclass->is_attribute('ins2', 'both') != 0, 'ins2 is instance by both');
Test::More::ok($subclass->is_attribute('trick', 'both') != 0, 'trick is class attribute by both');
Test::More::ok($subclass->is_attribute('class', 'both') != 0, 'class is class attribute by both');

Test::More::ok($subclass->is_attribute('fake_instance') == 0, 'fake_instance is not attribute by default');
Test::More::ok($subclass->is_attribute('fake_instance','both') == 0, 'fake_instance is not attribute by both');
Test::More::ok($subclass->is_attribute('fake_instance','instance') == 0, 'fake_instance is not attribute by instance');
Test::More::ok($subclass->is_attribute('fake_instance','class') == 0, 'fake_instance is not attribute by class');

Test::More::is(scalar $subclass->is_attribute('ins1', 'invalid'), undef, "invalid is_attribute flag is error condition");
Test::More::is($subclass->errcode, "BO-38", "proper error code");
};
{#line 1195 add_wrapper
my $subclass = "Basset::Test::Testing::Basset::Object::add_wrapper";
my $subclass2 = "Basset::Test::Testing::Basset::Object::add_wrapper2";

package Basset::Test::Testing::Basset::Object::add_wrapper;
our @ISA = qw(Basset::Object);

$subclass->add_attr('attr1');
$subclass->add_attr('attr2');
$subclass->add_attr('before_wrapper');
$subclass->add_attr('before_wrapper2');
$subclass->add_attr('after_wrapper');
$subclass->add_attr('after_wrapper2');
$subclass->add_attr('code_wrapper');

my ($meth1, $meth2, $meth3, $meth4);

sub meth1 {
	my $self = shift;
	$meth1 = shift if @_;
	return $meth1;
}

sub meth2 {
	my $self = shift;
	$meth2 = shift if @_;
	return $meth2;
}

sub meth3 {
	my $self = shift;
	$meth3 = shift if @_;
	return $meth3;
}

sub meth4 {
	my $self = shift;
	$meth4 = shift if @_;
	return $meth4;
}

sub wrapper1 {shift->before_wrapper('set')};

sub wrapper2 {
	$_[0]->before_wrapper('B4SET');
	$_[0]->before_wrapper2('set2');
}

sub wrapper3 {
	$_[0]->before_wrapper('ASET1');
	$_[0]->before_wrapper2('ASET2');
	return $_[2];
}

sub wrapper5 {
	$_[0]->before_wrapper('5-BSET1');
	$_[0]->before_wrapper2('5-BSET2');
	$_[0]->after_wrapper('5-ASET1');
	$_[0]->after_wrapper2('5-ASET2');
}

sub conditional_true {
	return 1;
}

sub conditional_false {
	my $self = shift;
	return $self->error("failed false condition", "conditional_false_error_code");
}

package Basset::Test::Testing::Basset::Object::add_wrapper2;
our @ISA = ($subclass);

sub wrapper4 {
	shift->after_wrapper('AWRAPPER');
}

package Basset::Object;

Test::More::ok(! $subclass->add_wrapper, "Cannot add wrapper w/o type");
Test::More::is($subclass->errcode, "BO-31", "proper error code");

Test::More::ok(! $subclass->add_wrapper('before'), "Cannot add wrapper w/o attribute");
Test::More::is($subclass->errcode, "BO-32", "proper error code");

Test::More::ok(! $subclass->add_wrapper('before', 'bogus_wrapper'), "Cannot add wrapper w/o wrapper");
Test::More::is($subclass->errcode, "BO-33", "proper error code");

Test::More::ok(! $subclass->add_wrapper('before', 'bogus_attribute', 'bogus_wrapper'), "Cannot add wrapper: bogus attribute");
Test::More::is($subclass->errcode, "BO-34", "proper error code");

Test::More::ok(! $subclass->add_wrapper('before', 'attr2', 'bogus_wrapper'), "Cannot add wrapper: cannot wrapper attributes");
Test::More::is($subclass->errcode, "BO-39", "proper error code");

Test::More::ok(! $subclass->add_wrapper('before', 'meth2', 'bogus_wrapper'), "Cannot add wrapper: bogus wrapper");
Test::More::is($subclass->errcode, "BO-35", "proper error code");

Test::More::ok(! $subclass->add_wrapper('junk', 'meth2', 'wrapper1'), "Cannot add wrapper: bogus type");
Test::More::is($subclass->errcode, "BO-36", "proper error code");

Test::More::ok(scalar $subclass->add_wrapper('before', 'meth1', 'wrapper1'), "added wrapper to ref");

my $o = $subclass->new();
Test::More::ok($o, "got object");

Test::More::is($o->before_wrapper, undef, "before_wrapper is undef");
Test::More::is($o->meth1('foo'), 'foo', 'set meth1 to foo');
Test::More::is($o->before_wrapper, 'set', 'before_wrapper is set');

Test::More::is($o->before_wrapper(undef), undef, "before_wrapper is undef");

Test::More::ok(scalar $subclass->add_wrapper('before', 'meth1', 'wrapper2'), "added wrapper to ref");

Test::More::is($o->before_wrapper, undef, "before_wrapper is undef");
Test::More::is($o->meth1('bar'), 'bar', 'set meth1 to baz');
Test::More::is($o->before_wrapper, 'set', 'before_wrapper is set');
Test::More::is($o->before_wrapper2, 'set2', 'before_wrapper2 is set2');
Test::More::is($o->after_wrapper, undef, 'after_wrapper is undef');
Test::More::is($o->after_wrapper2, undef, 'after_wrapper2 is undef');

Test::More::is($o->before_wrapper(undef), undef, "before_wrapper is undef");
Test::More::is($o->before_wrapper2(undef), undef, "before_wrapper2 is undef");

Test::More::ok(scalar $subclass->add_wrapper('after', 'meth1', 'wrapper3'), "added after wrapper to ref");

Test::More::is($o->before_wrapper, undef, "before_wrapper is undef");
Test::More::is($o->meth1('baz'), 'baz', 'set meth1 to baz');
Test::More::is($o->before_wrapper, 'ASET1', 'before_wrapper is ASET1');
Test::More::is($o->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');

my $o2 = $subclass2->new();
Test::More::ok($o2, "got sub object");

Test::More::ok(scalar $subclass2->add_wrapper('before', 'meth1', 'wrapper4'), "added after wrapper to ref");

Test::More::is($o2->before_wrapper, undef, "before_wrapper is undef");
Test::More::is($o2->meth1('baz'), 'baz', 'set meth1 to baz');
Test::More::is($o2->before_wrapper, 'ASET1', 'before_wrapper is ASET1');
Test::More::is($o2->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
Test::More::is($o2->after_wrapper, 'AWRAPPER', 'after_wrapper is AWRAPPER');

Test::More::is($o->before_wrapper(undef), undef, "before_wrapper is undef");
Test::More::is($o->before_wrapper2(undef), undef, "before_wrapper2 is undef");
Test::More::is($o->after_wrapper(undef), undef, "after_wrapper2 is undef");
Test::More::is($o->after_wrapper2(undef), undef, "after_wrapper2 is undef");

Test::More::ok(scalar $subclass->add_wrapper('before', 'meth1', 'wrapper5'), "added before wrapper to ref");

Test::More::is($o->before_wrapper, undef, "before_wrapper is undef");
Test::More::is($o->meth1('bar'), 'bar', 'set meth1 to baz');
Test::More::is($o->before_wrapper, 'ASET1', 'before_wrapper is set ASET1');
Test::More::is($o->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
Test::More::is($o->after_wrapper, '5-ASET1', 'after_wrapper is 5-ASET1');
Test::More::is($o->after_wrapper2, '5-ASET2', 'after_wrapper2 is 5-ASET2');

Test::More::is($o2->before_wrapper(undef), undef, "before_wrapper is undef");
Test::More::is($o2->before_wrapper2(undef), undef, "before_wrapper2 is undef");
Test::More::is($o2->after_wrapper(undef), undef, "after_wrapper2 is undef");
Test::More::is($o2->after_wrapper2(undef), undef, "after_wrapper2 is undef");

Test::More::is($o2->before_wrapper, undef, "before_wrapper is undef");
Test::More::is($o2->meth1('bar'), 'bar', 'set meth1 to baz');
Test::More::is($o2->before_wrapper, 'ASET1', 'before_wrapper is set ASET1');
Test::More::is($o2->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
Test::More::is($o2->after_wrapper, '5-ASET1', 'after_wrapper is 5-ASET1');
Test::More::is($o2->after_wrapper2, '5-ASET2', 'after_wrapper2 is 5-ASET2');

Test::More::is($o->before_wrapper(undef), undef, "before_wrapper is undef");
Test::More::is($o->before_wrapper2(undef), undef, "before_wrapper2 is undef");
Test::More::is($o->after_wrapper(undef), undef, "after_wrapper2 is undef");
Test::More::is($o->after_wrapper2(undef), undef, "after_wrapper2 is undef");

Test::More::is($o->before_wrapper, undef, "before_wrapper is undef");
Test::More::is($o->meth1('bar'), 'bar', 'set meth1 to baz');
Test::More::is($o->before_wrapper, 'ASET1', 'before_wrapper is set ASET1');
Test::More::is($o->before_wrapper2, 'ASET2', 'before_wrapper2 is ASET2');
Test::More::is($o->after_wrapper, '5-ASET1', 'after_wrapper is 5-ASET1');
Test::More::is($o->after_wrapper2, '5-ASET2', 'after_wrapper2 is 5-ASET2');

Test::More::ok(scalar $subclass->add_wrapper('before', 'meth1', sub {$_[0]->code_wrapper('SET CODE WRAP'); return 1}), 'added coderef wrapper');
Test::More::is($o->meth1('code'), 'code', 'set meth1 to code');
Test::More::is($o->code_wrapper, 'SET CODE WRAP', 'properly used coderef wrapper');

Test::More::ok(scalar $subclass->add_wrapper('before', 'meth3', 'wrapper1', 'conditional_true'), "added conditional_true wrapper");
Test::More::is($o->before_wrapper(undef), undef, "wiped out before_wrapper");
Test::More::is($o->meth3('meth 3 val'), 'meth 3 val', 'properly set method 3 value');
Test::More::is($o->before_wrapper, 'set', 'set before_wrapper');

Test::More::ok(scalar $subclass->add_wrapper('before', 'meth4', 'wrapper1', 'conditional_false'), "added conditional_false wrapper");
Test::More::is($o->before_wrapper(undef), undef, "wiped out before_wrapper");
Test::More::is($o->meth4('meth 4 val'), 'meth 4 val', 'could not set method 4 value');
Test::More::is($o->errcode, 'conditional_false_error_code', 'proper error code');
Test::More::is($o->before_wrapper, undef, 'could not set before_wrapper');
};
{#line 1484 error
my $notes = 0;

sub notifier {
	my $self = shift;
	my $note = shift;
	$notes++;
};

my $center = Basset::Object->pkg_for_type('notificationcenter');
Test::More::ok($center, "Got notification center class");

Test::More::ok(
	scalar
	$center->addObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'error',
		'object' => 'all',
		'method' => 'notifier'
	), "Added observer for error notifications"
);

my $o = Basset::Object->new();
Test::More::ok($o, "Object created");

Test::More::is(scalar Basset::Object->error("classerr"), undef, "Class error set and returns undef");
Test::More::is($notes, 1, "Posted a notification");
Test::More::is(scalar Basset::Object->error(), 'classerr', "Class error accesses");
Test::More::is($notes, 1, "No notification");

Test::More::is(scalar Basset::Object->error("classerr2", "classcode2"), undef, "Class error and errcode set and returns undef");
Test::More::is($notes, 2, "Posted a notification");
Test::More::is(scalar Basset::Object->error(), 'classerr2', "Class error accesses");
Test::More::is($notes, 2, "No notification");
Test::More::is(scalar Basset::Object->errcode(), 'classcode2', "Class Class errcode accesses");
Test::More::is($notes, 2, "No notification");

Test::More::is(scalar $o->error("objerr"), undef, "Object error set and returns undef");
Test::More::is($notes, 3, "Posted a notification");
Test::More::is(scalar $o->error(), 'objerr', "Object error accesses");
Test::More::is($notes, 3, "No notification");
Test::More::is(scalar Basset::Object->error(), 'classerr2', "Class error unaffected");
Test::More::is($notes, 3, "No notification");

Test::More::is(scalar $o->error("objerr2", "objcode2"), undef, "Object error and errcode set and returns undef");
Test::More::is($notes, 4, "Posted a notification");
Test::More::is(scalar $o->error(), 'objerr2', "Object error accesses");
Test::More::is($notes, 4, "No notification");
Test::More::is(scalar $o->errcode(), 'objcode2', "Object errcode accesses");
Test::More::is($notes, 4, "No notification");
Test::More::is(scalar Basset::Object->error(), 'classerr2', "Class error unaffected");
Test::More::is($notes, 4, "No notification");
Test::More::is(scalar Basset::Object->errcode(), 'classcode2', "Class errcode unaffected");
Test::More::is($notes, 4, "No notification");

Test::More::is(scalar Basset::Object->error("classerr3", "clscode3"), undef, "Re-set class error");
Test::More::is($notes, 5, "Posted notification");
Test::More::is(scalar $o->error(), 'objerr2', "Object error unchanged");
Test::More::is($notes, 5, "No notification");
Test::More::is(scalar $o->errcode(), 'objcode2', "Object errcode unchanged");
Test::More::is($notes, 5, "No notification");

Test::More::is(scalar $o->error("objerr3", "objcode3", "silently"), undef, "Silently set error");
Test::More::is($notes, 5, "No notification");
Test::More::is(scalar $o->error(), 'objerr3', "Object error accesses");
Test::More::is($notes, 5, "No notification");
Test::More::is(scalar $o->errcode(), 'objcode3', "Object errcode accesses");
Test::More::is($notes, 5, "No notification");
Test::More::is(scalar Basset::Object->error(), 'classerr3', "Class error unaffected");
Test::More::is($notes, 5, "No notification");
Test::More::is(scalar Basset::Object->errcode(), 'clscode3', "Class errcode unaffected");
Test::More::is($notes, 5, "No notification");

Test::More::is(scalar $o->error(["formatted error %d %.2f %s", 13, 3.14, "data"], "ec", "silently"), undef, "Object set formatted error");
Test::More::is(scalar $o->error, "formatted error 13 3.14 data", "Formatted error accesses");
Test::More::is(scalar $o->errcode, "ec", "Formatted errcode accesses");
Test::More::is(scalar Basset::Object->error(), 'classerr3', "Class error unaffected");
Test::More::is($notes, 5, "No notification");
Test::More::is(scalar Basset::Object->errcode(), 'clscode3', "Class errcode unaffected");
Test::More::is($notes, 5, "No notification");

my $confClass = Basset::Object->pkg_for_type('conf');
Test::More::ok($confClass, "Got conf");

my $cfg = $confClass->conf;
Test::More::ok($cfg, "Got configuration");

Test::More::ok($cfg->{"Basset::Object"}->{'exceptions'} = 1, "enables exceptions");

eval {
	$o->error("exception error", "excpcode");
};
Test::More::ok($@ =~ /^excpcode /, "Caught object exception code");
Test::More::is($o->last_exception, "exception error", "Caught object exception");
Test::More::is(Basset::Object->last_exception, "exception error", "Caught class exception");
Test::More::is($notes, 6, "Posted a notification");

eval {
	Basset::Object->error("exception error 2", "excpcode2");
};

Test::More::ok($@ =~ /^excpcode2 /, "Caught object exception code2");
Test::More::is($o->last_exception, "exception error 2", "Caught object exception");
Test::More::is(Basset::Object->last_exception, "exception error 2", "Caught class exception");
Test::More::is($notes, 7, "Posted a notification");

eval {
	Basset::Object->error("exception error 3", "excpcode3", "silently");
};
Test::More::ok($@ =~ /^excpcode3/, "Caught object exception code3");
Test::More::is($o->last_exception, "exception error 3", "Caught object exception");
Test::More::is(Basset::Object->last_exception, "exception error 3", "Caught class exception");
Test::More::is($notes, 7, "No notification");

Test::More::is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0,"shut off exceptions");

Test::More::ok(
	scalar
	$center->removeObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'error',
	), "Removed observer for error notifications"
);

package Basset::Test::Testing::Basset::Object::error::Subclass1;
our @ISA = qw(Basset::Object);

sub can {
	my $self = shift;
	my $method = shift;
	return 0 if $method =~ /_..._error/;
	return $self->SUPER::can($method);
};

package Basset::Object;
{
	local $@ = undef;

	eval {
		Basset::Test::Testing::Basset::Object::error::Subclass1->error("some error");
	};
	Test::More::like($@, qr/^System start up failure/, 'Could not start system when cannot error');
}

package Basset::Test::Testing::Basset::Object::error::Subclass2;
our @ISA = qw(Basset::Object);

sub can {
	my $self = shift;
	my $method = shift;
	return 0 if $method =~ /_..._errcode/;
	return $self->SUPER::can($method);
};

package Basset::Object;

{
	local $@ = undef;

	eval {
		Basset::Test::Testing::Basset::Object::error::Subclass2->error("some error");
	};

	Test::More::like($@, qr/^System start up failure/, 'Could not start system when cannot errcode');

	Test::More::is(scalar(Basset::Test::Testing::Basset::Object::error::Subclass2->error), undef, 'accessing error merely returns');

}
};
{#line 1741 rawerror
my $o = Basset::Object->new();
Test::More::ok($o, "Object created");

Test::More::is(scalar Basset::Object->error("raw class error", "roe"), undef, "Set class error");
Test::More::is(scalar Basset::Object->rawerror(), "raw class error", "Class raw error accesses");
Test::More::is(scalar Basset::Object->error(["raw class error %d"], "roe"), undef, "Set formatted class error");
Test::More::is(ref Basset::Object->rawerror(), 'ARRAY', "Class formatted raw error accesses");
Test::More::is(Basset::Object->rawerror()->[0], "raw class error %d", "Class formatted raw error accesses");

Test::More::is(scalar $o->error("raw object error", "roe"), undef, "Set object error");
Test::More::is(scalar $o->rawerror(), "raw object error", "Object raw error accesses");
Test::More::is(scalar $o->error(["raw object error %d"], "roe"), undef, "Set formatted object error");
Test::More::is(ref $o->rawerror(), 'ARRAY', "Object formatted raw error accesses");
Test::More::is($o->rawerror()->[0], 'raw object error %d', "Object formatted raw error accesses");
Test::More::ok(ref $o->rawerror() eq 'ARRAY', "Class formatted raw error unaffected");
Test::More::is(Basset::Object->rawerror()->[0], "raw class error %d", "Class formatted raw error unaffected");
};
{#line 1794 errcode
Test::More::is(scalar Basset::Object->error("test error", "test code", "silently"), undef, "Class sets errcode");
Test::More::is(scalar Basset::Object->errcode(), "test code", "Class accesses");
};
{#line 1821 errstring
Test::More::is(scalar Basset::Object->error("test error", "test code"), undef, "Class sets error & errcode");
Test::More::is(Basset::Object->errstring(), "test error...with code (test code)", "Class accesses errstring");

Test::More::is(scalar Basset::Object->error("test error2", "test code2", "silently"), undef, "Class silently sets error & errcode");
Test::More::is(Basset::Object->errstring(), "test error2...with code (test code2)", "Class accesses errstring");

Test::More::is(scalar Basset::Object->error("test error3"), undef, "Class sets error & no errcode");
Test::More::is(Basset::Object->errstring(), "test error3...with code (code undefined)", "Class accesses errstring");

Test::More::is(scalar Basset::Object->error("test error4", undef, "silently"), undef, "Class silently sets error & no errcode");
Test::More::is(Basset::Object->errstring(), "test error4...with code (code undefined)", "Class accesses errstring");

Basset::Object->wipe_errors();

Test::More::is(scalar(Basset::Object->errstring), undef, 'errcode returns nothing w/o error and errcode');
Basset::Object->errcode('test code');
Test::More::is(Basset::Object->errstring, 'error undefined...with code (test code)', 'errcode returns undefined w/o error');
};
{#line 1874 errvals
my $notes = 0;

sub notifier2 {
	my $self = shift;
	my $note = shift;
	$notes++;
};

my $center = Basset::Object->pkg_for_type('notificationcenter');
Test::More::ok($center, "Got notification center class");

Test::More::ok(
	scalar
	$center->addObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'error',
		'object' => 'all',
		'method' => 'notifier2'
	), "Added observer for error notifications"
);

my $o = Basset::Object->new();
Test::More::ok($o, "Object created");

Test::More::is(scalar $o->error("test error", "test code"), undef, "Object set error");
Test::More::is($notes, 1, "Posted notification");

my @errvals = $o->errvals;
Test::More::is($notes, 1, "No notification");
Test::More::is($errvals[0], "test error", "Object accesses error");
Test::More::is($notes, 1, "No notification");
Test::More::is($errvals[1], "test code", "Object accesses error");
Test::More::is($notes, 1, "No notification");
Test::More::is($errvals[2], "silently", "errvals always silent");
Test::More::is($notes, 1, "No notification");

Test::More::ok(
	scalar
	$center->removeObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'error',
	), "Removed observer for error notifications"
);
};
{#line 1947 usererror
my $translator = Basset::Object->errortranslator();
Test::More::ok(
	scalar
	Basset::Object->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2'
	}),
	'Class set error translator'
);

my $uses_real = Basset::Object->use_real_errors();
Test::More::is(Basset::Object->use_real_errors(0), 0, "Uses real errors");

Test::More::is(scalar Basset::Object->error("extra error", "test code"), undef, "Class sets error");
Test::More::is(Basset::Object->usererror(), "friendliest test message 2", "Class gets user error for literal");

Test::More::is(scalar Basset::Object->error(["formatted test error %d", 7], "test code"), undef, "Class sets formatted error");
Test::More::is(Basset::Object->usererror(), "friendliest test message", "Class gets user error for formatted string");

Test::More::is(scalar Basset::Object->error(["formatted test error %d", 9], "test code"), undef, "Class sets formatted error");
Test::More::is(Basset::Object->usererror(), "friendlier test message", "Class gets user error for string format");

Test::More::is(scalar Basset::Object->error("Some test error", "test code"), undef, "Class sets standard error");
Test::More::is(Basset::Object->usererror(), "friendly test message", "Class gets user error for error code");

Test::More::is(scalar Basset::Object->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
Test::More::is(Basset::Object->usererror(), "Some unknown error", "Class gets no user error");

Test::More::ok(
	scalar
	Basset::Object->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2',
		'*' => 'star error',
	}),
	'Class changed error translator'
);

Test::More::is(scalar Basset::Object->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
Test::More::is(Basset::Object->usererror(), "star error", "Class gets star error");

Test::More::is(Basset::Object->errortranslator($translator), $translator, 'Class reset error translator');
Test::More::is(Basset::Object->use_real_errors($uses_real), $uses_real, "resets uses real errors");
};
{#line 2052 wipe_errors
Test::More::is(scalar Basset::Object->error("test error", "error code"), undef, "Class set error and errcode");
Test::More::is(Basset::Object->error(), "test error", "Class accesses error");
Test::More::is(Basset::Object->errcode(), "error code", "Class accesses errcode");
Test::More::ok(scalar Basset::Object->wipe_errors(), "Class wiped errors");
Test::More::is(scalar Basset::Object->error(), undef, "Class error wiped out");
Test::More::is(scalar Basset::Object->errcode(), undef, "Class errcode wiped out");

my $confClass = Basset::Object->pkg_for_type('conf');
Test::More::ok($confClass, "Got conf");

my $cfg = $confClass->conf;
Test::More::ok($cfg, "Got configuration");

Test::More::ok($cfg->{"Basset::Object"}->{'exceptions'} = 1, "enables exceptions");

eval {
	Basset::Object->error("test exception", "test exception code");
};
Test::More::ok($@, "Caught exception");
Test::More::like($@, qr/test exception code/, "Exception matches");
Test::More::like(Basset::Object->last_exception, qr/test exception/, "Exception is present");
Test::More::ok(scalar Basset::Object->wipe_errors(), "Class wiped errors");
Test::More::is(Basset::Object->last_exception, undef, "last exception wiped out");
Test::More::is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0,"disables exceptions");
};
{#line 2124 notify
my $test1notes = undef;
my $test2notes = undef;

sub test1notifier {
	my $self = shift;
	my $note = shift;
	$test1notes = $note->{'args'}->[0];
};

sub test2notifier {
	my $self = shift;
	my $note = shift;
	$test2notes = $note->{'args'}->[0];
};

my $center = Basset::Object->pkg_for_type('notificationcenter');
Test::More::ok($center, "Got notification center class");

Test::More::ok(
	scalar
	$center->addObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'test1',
		'object' => 'all',
		'method' => 'test1notifier'
	), "Added observer for test1 notifications"
);

Test::More::ok(
	scalar
	$center->addObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'test2',
		'object' => 'all',
		'method' => 'test2notifier'
	), "Added observer for test2 notifications"
);

my $o = Basset::Object->new();
Test::More::ok($o, "Object created");

Test::More::ok(scalar Basset::Object->notify('test1', "Test 1 note 1"), "Class posted notification");
Test::More::is($test1notes, "Test 1 note 1", "Received note");
Test::More::is($test2notes, undef, "No note for test 2");

Test::More::ok(scalar Basset::Object->notify('test2', "Test 2 note 2"), "Class posted notification");
Test::More::is($test2notes, "Test 2 note 2", "Received note");
Test::More::is($test1notes, "Test 1 note 1", "Test 1 note unchanged");

Test::More::ok(
	scalar
	$center->removeObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'test1',
	), "Removed observer for test1 notifications"
);

Test::More::ok(
	scalar
	$center->addObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'test1',
		'object' => $o,
		'method' => 'test1notifier'
	), "Added specific observer for test1 notifications"
);

Test::More::ok(scalar Basset::Object->notify('test1', 'Test 1 note 2'), "Class posted notification");
Test::More::is($test1notes, "Test 1 note 1", "Test 1 note unchanged");
Test::More::is($test2notes, "Test 2 note 2", "Test 2 note unchanged");

Test::More::ok(scalar $o->notify('test1', 'Test 1 note 3'), "Object posted notification");
Test::More::is($test1notes, "Test 1 note 3", "Recieved note");

Test::More::is($test2notes, "Test 2 note 2", "Test 2 note unchanged");

Test::More::ok(
	scalar
	$center->removeObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'test1',
	), "Removed observer for test1 notifications"
);

Test::More::ok(
	scalar
	$center->removeObserver(
		'observer' => 'Basset::Object',
		'notification'	=> 'test2',
	), "Removed observer for test2 notifications"
);
};
{#line 2280 add_restrictions
package Basset::Test::Testing::Basset::Object::add_restrictions::Subclass1;
our @ISA = qw(Basset::Object);

my %restrictions = (
	'specialerror' => [
		'error' => 'error2',
		'errcode' => 'errcode2'
	],
	'invalidrestriction' => [
		'junkymethod' => 'otherjunkymethod'
	]
);

Test::More::ok(scalar Basset::Test::Testing::Basset::Object::add_restrictions::Subclass1->add_restrictions(%restrictions), "Added restrictions to subclass");
};
{#line 2350 add_restricted_method
package Basset::Test::Testing::Basset::Object::add_restricted_method::Subclass1;
our @ISA = qw(Basset::Object);

my %restrictions = (
	'specialerror' => [
		'error' => 'error2',
		'errcode' => 'errcode2'
	],
	'invalidrestriction' => [
		'junkymethod' => 'otherjunkymethod'
	]
);

Basset::Object->add_class_attr('e2');
Basset::Object->add_class_attr('c2');

Test::More::is(Basset::Object->e2(0), 0, "set e2 to 0");
Test::More::is(Basset::Object->c2(0), 0, "set c2 to 0");

sub error2 {
	my $self = shift;
	$self->e2($self->e2 + 1);
	return $self->SUPER::error(@_);
}

sub errcode2 {
	my $self = shift;
	$self->c2($self->c2 + 1);
	return $self->SUPER::errcode(@_);
}

Test::More::ok(scalar Basset::Test::Testing::Basset::Object::add_restricted_method::Subclass1->add_restrictions(%restrictions), "Added restrictions to subclass");

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::add_restricted_method::Subclass1->isa('Basset::Object'), 'Proper subclass');

my $subclass = Basset::Test::Testing::Basset::Object::add_restricted_method::Subclass1->inline_class();
Test::More::ok(scalar $subclass, "Got restricted class");
Test::More::ok($subclass->restricted, "Subclass is restricted");
Test::More::ok(scalar $subclass->isa('Basset::Test::Testing::Basset::Object::add_restricted_method::Subclass1'), "Is subclass");
Test::More::ok(scalar $subclass->isa('Basset::Object'), "Is subclass");

Test::More::ok(scalar $subclass->add_restricted_method('specialerror', 'error'), "Restricted error");
Test::More::ok(scalar $subclass->add_restricted_method('specialerror', 'errcode'), "Restricted errcode");
Test::More::ok(! scalar $subclass->add_restricted_method('invalidrestriction', 'junkymethod'), "Could not add invalid restriction");

Test::More::ok(! scalar $subclass->add_restricted_method('specialerror', 'error2'), "Could not add invalid restricted method");
Test::More::ok(! scalar $subclass->add_restricted_method('specialerror', 'errcode2'), "Could not add invalid restricted method");
Test::More::ok(! scalar $subclass->add_restricted_method('specialerror', 'junkymethod2'), "Could not add invalid restricted method");

my $e2 = $subclass->e2;
my $c2 = $subclass->c2;

#we post silently or else error and errcode would be called when it posts the error notification.
Test::More::is(scalar $subclass->error("test error", "test code", "silently"), undef, "Set error for subclass");

Test::More::is($subclass->e2, $e2 + 1, "Subclass restricted error incremented");
Test::More::is($subclass->c2, $c2, "Subclass restricted errcode unchanged");
Test::More::is($subclass->error(), "test error", "Subclass accesses error method");
Test::More::is($subclass->e2, $e2 + 2, "Subclass restricted error incremented");
Test::More::is($subclass->c2, $c2, "Subclass restricted errcode unchanged");
Test::More::is($subclass->errcode(), "test code", "Subclass accesses errcode method");
Test::More::is($subclass->e2, $e2 + 2, "Subclass restricted error unchanged");
Test::More::is($subclass->c2, $c2 + 1, "Subclass restricted errcode incremented");

Test::More::is(scalar Basset::Test::Testing::Basset::Object::add_restricted_method::Subclass1->error("super test error", "super test code", "silently"), undef, "Superclass sets error");
Test::More::is($subclass->e2, $e2 + 2, "Subclass restricted error unchanged");
Test::More::is($subclass->c2, $c2 + 1, "Subclass restricted errcode unchanged");
};
{#line 2487 failed_restricted_method
package Basset::Test::Testing::Basset::Object::failed_restricted_method::Subclass2;
our @ISA = qw(Basset::Object);

sub successful {
	return 1;
};

my %restrictions = (
	'failure' => [
		'successful' => 'failed_restricted_method',
	],
);

package Basset::Object;

my $subclass = Basset::Test::Testing::Basset::Object::failed_restricted_method::Subclass2->inline_class;
Test::More::ok($subclass, "Got restricted subclass");
Test::More::ok(scalar $subclass->restricted, "Subclass is restricted");
Test::More::ok(scalar $subclass->add_restrictions(%restrictions), "Subclass added restrictions");

Test::More::ok(! scalar Basset::Object->failed_restricted_method, "Failed restricted method always fails");
Test::More::ok(! scalar Basset::Test::Testing::Basset::Object::failed_restricted_method::Subclass2->failed_restricted_method, "Failed restricted method always fails");
Test::More::ok(! scalar $subclass->failed_restricted_method, "Failed restricted method always fails");

Test::More::ok(scalar Basset::Test::Testing::Basset::Object::failed_restricted_method::Subclass2->successful, "Super Success is successful");
Test::More::ok(scalar $subclass->successful, "Subclass success is successful");
Test::More::ok(scalar $subclass->add_restricted_method('failure', 'successful'), "Restricted subclass to fail upon success");
Test::More::ok(scalar Basset::Test::Testing::Basset::Object::failed_restricted_method::Subclass2->successful, "Super Success is successful");
Test::More::ok(! scalar $subclass->successful, "Subclass success fails");
};
{#line 2541 inline_class
my $class = Basset::Object->inline_class();
Test::More::ok($class, "Got restricted class");
Test::More::ok($class->restricted(), "Class is restricted");
Test::More::ok(! Basset::Object->restricted(), "Superclass is not restricted");
};
{#line 2585 load_pkg
my $iclass = Basset::Object->inline_class;
Test::More::ok(scalar Basset::Object->load_pkg($iclass), "Can load inline class");
};
{#line 2613 restrict
package Basset::Test::Testing::Basset::Object::restrict::Subclass1;
our @ISA = qw(Basset::Object);

sub successful {
	return 1;
};

my %restrictions = (
	'failure' => [
		'successful' => 'failed_restricted_method',
	],
);

Test::More::ok(Basset::Test::Testing::Basset::Object::restrict::Subclass1->add_restrictions(%restrictions), "Subclass added restrictions");

package Basset::Object;

Test::More::ok(scalar Basset::Object->can('failed_restricted_method'), "Basset::Object has failed_restricted_method");
Test::More::ok(scalar Basset::Test::Testing::Basset::Object::restrict::Subclass1->can('failed_restricted_method'), "Subclass has failed_restricted_method");

Test::More::ok(Basset::Test::Testing::Basset::Object::restrict::Subclass1->isa('Basset::Object'), 'Proper subclass');
Test::More::ok(! scalar Basset::Object->failed_restricted_method, "Method properly fails");
Test::More::ok(! scalar Basset::Test::Testing::Basset::Object::restrict::Subclass1->failed_restricted_method, "Method properly fails");

my $subclass = Basset::Test::Testing::Basset::Object::restrict::Subclass1->restrict('failure');

Test::More::ok($subclass, "Got restricted subclass");

Test::More::ok($subclass->restricted, "Subclass is restricted");
Test::More::ok(! Basset::Test::Testing::Basset::Object::restrict::Subclass1->restricted, "Superclass unaffected");
Test::More::ok(! Basset::Object->restricted, "Superclass unaffected");

Test::More::ok(! scalar $subclass->successful, "Subclass restricted");
Test::More::ok(scalar Basset::Test::Testing::Basset::Object::restrict::Subclass1->successful, "Superclass unaffected");

Test::More::ok(scalar Basset::Test::Testing::Basset::Object::restrict::Subclass1->restrict('worthless restriction'), "Added unknown restriction");
};
{#line 2710 nonrestricted_parent
package Basset::Test::Testing::Basset::Object::nonrestricted_parent::Subclass1;
our @ISA = qw(Basset::Object);

package Basset::Object;

Test::More::is(Basset::Object->nonrestricted_parent, "Basset::Object", "Basset::Object own nonrestricted parent");
Test::More::is(Basset::Test::Testing::Basset::Object::nonrestricted_parent::Subclass1->nonrestricted_parent, "Basset::Test::Testing::Basset::Object::nonrestricted_parent::Subclass1", "Subclass own nonrestricted parent");

my $subclass = Basset::Test::Testing::Basset::Object::nonrestricted_parent::Subclass1->inline_class;
Test::More::ok($subclass, "Got restricted class");
Test::More::is($subclass->nonrestricted_parent, "Basset::Test::Testing::Basset::Object::nonrestricted_parent::Subclass1", "Restricted class has proper non restricted parent");

my $subclass2 = $subclass->inline_class;
Test::More::ok($subclass2, "Got restricted class of restricted class");
Test::More::is($subclass2->nonrestricted_parent, "Basset::Test::Testing::Basset::Object::nonrestricted_parent::Subclass1", "Restricted class has proper non restricted parent");

my $subclass3 = Basset::Object->inline_class;
Test::More::ok($subclass3, "Got restricted class");
Test::More::is($subclass3->nonrestricted_parent, "Basset::Object", "Restricted class has proper non restricted parent");
};
{#line 2768 dump
my $o = Basset::Object->new();
Test::More::ok($o, "Created object");
my $o2 = Basset::Object->new();
Test::More::ok($o2, "Created object");

Test::More::ok($o->dump, "Dumped object");
Test::More::ok($o->dump(['a']), "Dumped array");
Test::More::ok($o->dump({'k' => 'v'}), "Dumped hash");
Test::More::ok($o2->dump, "Dumped other object");
Test::More::is($o->dump($o2), $o2->dump, "Dumps equal");
Test::More::is($o->dump, $o2->dump($o), "Dumps equal");
};
{#line 2843 new
my $o = Basset::Object->new();

Test::More::ok($o, "created a new object");

package Basset::Test::Testing::Basset::Object::new::Subclass1;
our @ISA = qw(Basset::Object);

Basset::Test::Testing::Basset::Object::new::Subclass1->add_attr('attr1');
Basset::Test::Testing::Basset::Object::new::Subclass1->add_attr('attr2');
Basset::Test::Testing::Basset::Object::new::Subclass1->add_attr('attr3');
Basset::Test::Testing::Basset::Object::new::Subclass1->add_class_attr('class_attr');

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::new::Subclass1->isa('Basset::Object'), "Subclass is subclass");
Test::More::ok(Basset::Test::Testing::Basset::Object::new::Subclass1->can('attr1'), 'class can attr1');
Test::More::ok(Basset::Test::Testing::Basset::Object::new::Subclass1->can('attr2'), 'class can attr2');
Test::More::ok(Basset::Test::Testing::Basset::Object::new::Subclass1->can('attr3'), 'class can attr3');
Test::More::ok(Basset::Test::Testing::Basset::Object::new::Subclass1->can('class_attr'), 'class can class_attr');

my $o2 = Basset::Test::Testing::Basset::Object::new::Subclass1->new();
Test::More::ok($o2, "created a subclass object");

my $o3 = Basset::Test::Testing::Basset::Object::new::Subclass1->new(
	'attr1' => 'attr1val',
);

Test::More::ok($o3, "Created a subclass object");
Test::More::is(scalar $o3->attr1, 'attr1val', 'subclass object has attribute from constructor');

my $o4 = Basset::Test::Testing::Basset::Object::new::Subclass1->new(
	'attr1' => 'attr1val',
	'attr2' => 'attr2val',
);

Test::More::ok($o4, "Created a subclass object");
Test::More::is(scalar $o4->attr1, 'attr1val', 'subclass object has attribute from constructor');
Test::More::is(scalar $o4->attr2, 'attr2val', 'subclass object has attribute from constructor');

my $o5 = Basset::Test::Testing::Basset::Object::new::Subclass1->new(
	'attr1' => 'attr1val',
	'attr2' => 'attr2val',
	'attr7' => 'attr7val',
	'attr8' => 'attr8val',
);

Test::More::ok($o5, "Created a subclass object w/junk values");
Test::More::is(scalar $o5->attr1, 'attr1val', 'subclass object has attribute from constructor');
Test::More::is(scalar $o5->attr2, 'attr2val', 'subclass object has attribute from constructor');

#these tests would now pass.
#my $o6 = Basset::Test::Testing::Basset::Object::new::Subclass1->new(
#	'attr1' => undef,
#);
#
#Test::More::ok(! $o6, "Failed to create object w/undef value");

my $o7 = Basset::Test::Testing::Basset::Object::new::Subclass1->new(
	'attr1' => 7,
	'attr2' => 0,
);

Test::More::ok($o7, "Created object w/0 value");
Test::More::is($o7->attr1, 7, 'attr1 value set');
Test::More::is($o7->attr2, 0, 'attr2 value set');

my $o8 = Basset::Test::Testing::Basset::Object::new::Subclass1->new(
	{
		'attr1' => 8,
		'attr2' => 9
	},
	'attr1' => 7
);

Test::More::ok($o8, "Created object w/0 value");
Test::More::is($o8->attr1, 7, 'attr1 value set');
Test::More::is($o8->attr2, 9, 'attr2 value set');
};
{#line 2998 init
package Basset::Test::Testing::Basset::Object::init::Subclass2;
our @ISA = qw(Basset::Object);

sub conf {
	return undef;
};

package Basset::Object;

{
	my $o = undef;
	local $@ = undef;
	$o = Basset::Test::Testing::Basset::Object::init::Subclass2->new();
	Test::More::is($o, undef, 'could not create object w/o conf file');
}

{
	my $o = Basset::Object->new('__j_known_junk_method' => 'a');
	Test::More::ok($o, 'created object');
}

package Basset::Test::Testing::Basset::Object::init::Subclass3;
our @ISA = qw(Basset::Object);
my $subclass = 'Basset::Test::Testing::Basset::Object::init::Subclass3';

sub known_failure {
	my $self = shift;
	return $self->error("I failed", "known_error_code");
}

sub known_failure_2 {
	my $self = shift;
	return;
}

my $obj1 =  $subclass->new();
Test::More::ok($obj1, "Got empty object w/o known failure");

my $obj2 =  $subclass->new(
	'known_failure' => 1
);

Test::More::is($obj2, undef, "obj2 not created because of known_failure");
Test::More::is($subclass->errcode, 'known_error_code', 'proper error code');

my $obj3 =  $subclass->new(
	'known_failure_2' => 1
);

Test::More::is($obj3, undef, "obj3 not created because of known_failure_2");
Test::More::is($subclass->errcode, 'BO-03', 'proper error code');
};
{#line 3116 pkg
package main::Basset::Test::Testing::Basset::Object::MainSubClass;
our @ISA = qw(Basset::Object);

package Basset::Test::Testing::Basset::Object::MainSubClass2;
our @ISA = qw(Basset::Object);

package ::Basset::Test::Testing::Basset::Object::MainSubClass3;
our @ISA = qw(Basset::Object);

package Basset::Object;

Test::More::ok(main::Basset::Test::Testing::Basset::Object::MainSubClass->isa('Basset::Object'), "Created subclass");
Test::More::ok(Basset::Test::Testing::Basset::Object::MainSubClass2->isa('Basset::Object'), "Created subclass");
Test::More::ok(Basset::Test::Testing::Basset::Object::MainSubClass3->isa('Basset::Object'), "Created subclass");

my $o = Basset::Object->new();
Test::More::ok($o, "Created object");

my $so1 = main::Basset::Test::Testing::Basset::Object::MainSubClass->new();
Test::More::ok($so1, "Created sub-object");

my $so2 = Basset::Test::Testing::Basset::Object::MainSubClass2->new();
Test::More::ok($so2, "Created sub-object");

my $so3 = Basset::Test::Testing::Basset::Object::MainSubClass3->new();
Test::More::ok($so3, "Created sub-object");

Test::More::is($o->pkg, "Basset::Object", "Superclass works");
Test::More::is($so1->pkg, "Basset::Test::Testing::Basset::Object::MainSubClass", "Subclass works");
Test::More::is($so2->pkg, "Basset::Test::Testing::Basset::Object::MainSubClass2", "Subclass works");
Test::More::is($so3->pkg, "Basset::Test::Testing::Basset::Object::MainSubClass3", "Subclass works");
};
{#line 3190 factory
package Basset::Test::Testing::Basset::Object::factory::Subclass;
our @ISA = qw(Basset::Object);

package Basset::Object;

my $oldtypes = Basset::Object->types();
Test::More::ok($oldtypes, "Saved old types");
my $newtypes = {%$oldtypes, 'factory_test_type' => 'Basset::Object'};
Test::More::is(Basset::Object->types($newtypes), $newtypes, "Set new types");
Test::More::is(Basset::Object->pkg_for_type('factory_test_type'), 'Basset::Object', 'can get class for type');
my $o = Basset::Object->new();
Test::More::ok($o, "Created new object");
my $o2 = Basset::Object->factory('type' => 'factory_test_type');
Test::More::ok($o2, "Factoried new object");
Test::More::ok($o2->isa('Basset::Object'), "Factory object isa class object");
Test::More::is(Basset::Object->types($oldtypes), $oldtypes, "reset old types");
};
{#line 3246 copy
package Basset::Test::Testing::Basset::Object::copy::subclass;
our @ISA = qw(Basset::Object);

Basset::Test::Testing::Basset::Object::copy::subclass->add_attr('attr1');
Basset::Test::Testing::Basset::Object::copy::subclass->add_attr('attr2');
Basset::Test::Testing::Basset::Object::copy::subclass->add_attr('attr3');

package Basset::Object;

my $o = Basset::Object->new();
Test::More::ok($o, "Instantiated object");
my $o2 = $o->copy;
Test::More::ok($o2, "Copied object");
Test::More::is(length $o->dump, length $o2->dump, "dumps are same size");

my $o3 = Basset::Test::Testing::Basset::Object::copy::subclass->new(
	'attr1' => 'first attribute',
	'attr2' => 'second attribute',
	'attr3' => 'third attribute'
);

Test::More::ok($o3, "Instantiated sub-object");

Test::More::is($o3->attr1, 'first attribute', 'Subobject attr1 matches');
Test::More::is($o3->attr2, 'second attribute', 'Subobject attr2 matches');
Test::More::is($o3->attr3, 'third attribute', 'Subobject attr3 matches');

my $o4 = $o3->copy;

Test::More::ok($o4, "Copied sub-object");

Test::More::is($o4->attr1, 'first attribute', 'Copied subobject attr1 matches');
Test::More::is($o4->attr2, 'second attribute', 'Copied subobject attr2 matches');
Test::More::is($o4->attr3, 'third attribute', 'Copied subobject attr3 matches');

Test::More::is(length $o3->dump, length $o4->dump, "Sub object dumps are same size");

my $array = ['a', 2, {'foo' => 'bar'}];

Test::More::ok($array, "Got array");

my $array2 = Basset::Object->copy($array);

Test::More::ok($array2, "Copied array");
Test::More::is($array->[0], $array2->[0], "First element matches");
Test::More::is($array->[1], $array2->[1], "Second element matches");
Test::More::is($array->[2]->{'foo'}, $array2->[2]->{'foo'}, "Third element matches");
};
{#line 3325 pkg_for_type
Test::More::ok(Basset::Object->types, "Got types out of the conf file");
my $typesbkp = Basset::Object->types();
my $newtypes = {%$typesbkp, 'testtype1' => 'Basset::Object', 'testtype2' => 'boguspkg'};
Test::More::ok($typesbkp, "Backed up the types");
Test::More::is(Basset::Object->types($newtypes), $newtypes, "Set new types");
Test::More::is(Basset::Object->pkg_for_type('testtype1'), 'Basset::Object', "Got class for new type");
Test::More::ok(! scalar Basset::Object->pkg_for_type('testtype2'), "Could not access invalid type");
Test::More::is(Basset::Object->errcode, 'BO-29', 'proper error code');

Basset::Object->wipe_errors;
Test::More::is(scalar(Basset::Object->pkg_for_type('testtype2', 'errorless')), undef, "Could not access invalid type w/ second arg");
Test::More::is(scalar(Basset::Object->errcode), undef, 'no error code set w/second arg');
Test::More::is(scalar(Basset::Object->errstring), undef, 'no error string set w/second arg');

my $h = {};

Test::More::is(Basset::Object->types($h), $h, 'wiped out types');
Test::More::is(scalar(Basset::Object->pkg_for_type('testtype3')), undef, 'could not get type w/o types');
Test::More::is(Basset::Object->errcode, 'BO-09', 'proper error code for no types');

Test::More::is(Basset::Object->types($typesbkp), $typesbkp, "Re-set original types");
};
{#line 3515 inherits
package Basset::Test::Testing::Basset::Object::inherits::Subclass1;
Basset::Object->inherits('Basset::Test::Testing::Basset::Object::inherits::Subclass1', 'object');

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::inherits::Subclass1->isa('Basset::Object'), 'subclass inherits from root');
};
{#line 3541 isa_path
Test::More::ok(Basset::Object->isa_path, "Can get an isa_path for root");
my $path = Basset::Object->isa_path;
Test::More::is($path->[-1], 'Basset::Object', 'Class has self at end of path');

package Basset::Test::Testing::Basset::Object::isa_path::subclass1;
our @ISA = qw(Basset::Object);

package Basset::Test::Testing::Basset::Object::isa_path::subclass2;
our @ISA = qw(Basset::Test::Testing::Basset::Object::isa_path::subclass1);

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::isa_path::subclass1->isa('Basset::Object'), 'Subclass of Basset::Object');
Test::More::ok(Basset::Test::Testing::Basset::Object::isa_path::subclass2->isa('Basset::Object'), 'Sub-subclass of Basset::Object');
Test::More::ok(Basset::Test::Testing::Basset::Object::isa_path::subclass1->isa('Basset::Test::Testing::Basset::Object::isa_path::subclass1'), 'Sub-subclass of subclass');

Test::More::ok(Basset::Test::Testing::Basset::Object::isa_path::subclass1->isa_path, "We have a path");
my $subpath = Basset::Test::Testing::Basset::Object::isa_path::subclass1->isa_path;
Test::More::is($subpath->[-2], 'Basset::Object', 'Next to last entry is parent');
Test::More::is($subpath->[-1], 'Basset::Test::Testing::Basset::Object::isa_path::subclass1', 'Last entry is self');

Test::More::ok(Basset::Test::Testing::Basset::Object::isa_path::subclass2->isa_path, "We have a sub path");
my $subsubpath = Basset::Test::Testing::Basset::Object::isa_path::subclass2->isa_path;

Test::More::is($subsubpath->[-3], 'Basset::Object', 'Third to last entry is grandparent');
Test::More::is($subsubpath->[-2], 'Basset::Test::Testing::Basset::Object::isa_path::subclass1', 'Second to last entry is parent');
Test::More::is($subsubpath->[-1], 'Basset::Test::Testing::Basset::Object::isa_path::subclass2', 'Last entry is self');

package Basset::Test::Testing::Basset::Object::isa_path::Subclass3;

our @ISA = qw(Basset::Object Basset::Object);

package Basset::Object;

my $isa = Basset::Test::Testing::Basset::Object::isa_path::Subclass3->isa_path;
Test::More::ok($isa, "Got isa path");

#Test::More::is(scalar(@$isa), 2, 'two entries in isa_path');
Test::More::is($isa->[-2], 'Basset::Object', 'Second to last entry is parent');
Test::More::is($isa->[-1], 'Basset::Test::Testing::Basset::Object::isa_path::Subclass3', 'Last entry is self');
};
{#line 3635 module_for_class
Test::More::is(scalar(Basset::Object->module_for_class), undef, "Could not get module_for_class w/o package");
Test::More::is(Basset::Object->errcode, "BO-20", 'proper error code');
Test::More::is(Basset::Object->module_for_class('Basset::Object'), 'Basset/Object.pm', 'proper pkg -> file name');
Test::More::is(Basset::Object->module_for_class('Basset::Object::Persistent'), 'Basset/Object/Persistent.pm', 'proper pkg -> file name');
Test::More::is(Basset::Object->module_for_class('Basset::DB::Table'), 'Basset/DB/Table.pm', 'proper pkg -> file name');
};
{#line 3668 conf
Test::More::ok(scalar Basset::Object->conf, "Class accessed conf file");
my $o = Basset::Object->new();
Test::More::ok(scalar $o, "Got object");
Test::More::ok(scalar $o->conf, "Object accessed conf file");
};
{#line 3706 today
Test::More::like(Basset::Object->today, qr/^\d\d\d\d-\d\d-\d\d$/, 'matches date regex');
Test::More::like(Basset::Object->today('abc'), qr/^\d\d\d\d-\d\d-\d\d$/, 'matches date regex despite input');
};
{#line 3729 now
Test::More::like(Basset::Object->now, qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/, 'matches timestamp regex');
Test::More::like(Basset::Object->now('def'), qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/, 'matches timestamp regex despite input');
};
{#line 3757 gen_handle
Test::More::ok(Basset::Object->gen_handle, "Generated handle");
my $h = Basset::Object->gen_handle;
Test::More::ok($h, "Generated second handle");
Test::More::is(ref $h, "GLOB", "And it's a globref");
};
{#line 3832 perform
package Basset::Test::Testing::Basset::Object::perform::Subclass;
our @ISA = qw(Basset::Object);

Basset::Test::Testing::Basset::Object::perform::Subclass->add_attr('attr1');
Basset::Test::Testing::Basset::Object::perform::Subclass->add_attr('attr2');
Basset::Test::Testing::Basset::Object::perform::Subclass->add_attr('attr3');

sub method1 {
	return 77;
}

sub method2 {
	my $self = shift;
	return scalar @_;
};

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::perform::Subclass->isa('Basset::Object'), 'we have a subclass');
Test::More::ok(Basset::Test::Testing::Basset::Object::perform::Subclass->can('attr1'), 'subclass has attr1');
Test::More::ok(Basset::Test::Testing::Basset::Object::perform::Subclass->can('attr2'), 'subclass has attr2');
Test::More::ok(Basset::Test::Testing::Basset::Object::perform::Subclass->can('attr2'), 'subclass has attr3');
Test::More::ok(Basset::Test::Testing::Basset::Object::perform::Subclass->can('method1'), 'subclass has method1');
Test::More::ok(Basset::Test::Testing::Basset::Object::perform::Subclass->can('method2'), 'subclass has method2');
Test::More::is(scalar Basset::Test::Testing::Basset::Object::perform::Subclass->method1, 77, 'method1 returns 77');
Test::More::is(scalar Basset::Test::Testing::Basset::Object::perform::Subclass->method2, 0, 'method2 behaves as expected');
Test::More::is(scalar Basset::Test::Testing::Basset::Object::perform::Subclass->method2('a'), 1, 'method2 behaves as expected');
Test::More::is(scalar Basset::Test::Testing::Basset::Object::perform::Subclass->method2(0,0), 2, 'method2 behaves as expected');

my $o = Basset::Test::Testing::Basset::Object::perform::Subclass->new();

Test::More::ok($o, "Instantiated object");

my $class = 'Basset::Test::Testing::Basset::Object::perform::Subclass';

Test::More::is(scalar($class->perform), undef, "Cannot perform w/o method");
Test::More::is($class->errcode, 'BO-04', 'proper error code');
Test::More::is(scalar($class->perform('methods' => 'able')), undef, "Cannot perform w/o values");
Test::More::is($class->errcode, 'BO-05', 'proper error code');
Test::More::is(scalar($class->perform('methods' => 'able', 'values' => 'baker')), undef, "methods must be arrayref");
Test::More::is($class->errcode, 'BO-11', 'proper error code');
Test::More::is(scalar($class->perform('methods' => ['able'], 'values' => 'baker')), undef, "values must be arrayref");
Test::More::is($class->errcode, 'BO-12', 'proper error code');

Test::More::ok(
	scalar Basset::Test::Testing::Basset::Object::perform::Subclass->perform(
		'methods' => ['method1'],
		'values' => ['a'],
	),
	"Class performs method1");

Test::More::ok(
	scalar $o->perform(
		'methods' => ['method1'],
		'values' => ['a'],
	),
	"Object performs method1");

Test::More::ok(! 
	scalar Basset::Test::Testing::Basset::Object::perform::Subclass->perform(
		'methods' => ['method2'],
		'values' => [],
	),
	"Class cannot perform method2 w/o args");

Test::More::ok(
	scalar Basset::Test::Testing::Basset::Object::perform::Subclass->perform(
		'methods' => ['method2'],
		'values' => ['a']
	),
	"Class performs method2 w/1 arg");

Test::More::ok(
	scalar Basset::Test::Testing::Basset::Object::perform::Subclass->perform(
		'methods' => ['method2'],
		'values' => ['b'],
	),
	"Class performs method2 w/1 arg in arrayref");

Test::More::ok(! 
	scalar $o->perform(
		'methods' => ['attr1'],
		'values' => []
	),
	"object cannot access attribute w/o args"
);

Test::More::is(scalar $o->attr1, undef, 'attr1 is undefined');
Test::More::is(scalar $o->attr2, undef, 'attr2 is undefined');
Test::More::is(scalar $o->attr3, undef, 'attr3 is undefined');

Test::More::ok(
	scalar $o->perform(
		'methods' => ['attr1'],
		'values' => ['attr1_val']
	),
	"object performed attr1"
);

Test::More::is(scalar $o->attr1(), 'attr1_val', 'attr1 set via perform');

Test::More::ok(
	scalar $o->perform(
		'methods' => ['attr2', 'attr3'],
		'values' => ['attr2_val', 'attr3_val']
	),
	"object performed attr2, attr3"
);

Test::More::is(scalar $o->attr2(), 'attr2_val', 'attr2 set via perform');
Test::More::is(scalar $o->attr3(), 'attr3_val', 'attr3 set via perform');

Test::More::ok(! 
	scalar $o->perform(
		'methods' => ['attr4'],
		'values' => ['attr4_val']
	),
	"object cannot perform unknown method"
);

Test::More::ok(! 
	scalar $o->perform(
		'methods' => ['attr4', 'attr2'],
		'values' => ['attr4_val', 'attr2_val_2'],
	),
	'object cannot perform unknown method w/known method'
);

Test::More::is(scalar $o->attr2, 'attr2_val', 'attr2 unchanged');

Test::More::ok(! 
	scalar $o->perform(
		'methods' => ['attr1'],
		'values' => [undef]
	),
	"object failed trying to perform attr1"
);

Test::More::ok(! 
	scalar $o->perform(
		'methods' => ['attr1', 'attr2'],
		'values' => [undef, 'attr2_val_2'],
	),
	'object failed trying to perform attr1'
);

Test::More::is(scalar $o->attr2, 'attr2_val', 'attr2 unchanged');

Test::More::ok(! 
	scalar $o->perform(
		'methods' => ['attr1', 'attr2'],
		'values' => [undef, 'attr2_val_2'],
		'continue' => 1,
	),
	'object failed trying to perform attr1'
);

Test::More::is(scalar $o->attr2, 'attr2_val_2', 'attr2 changed due to continue');

my $arr = ['a', 'b'];
Test::More::ok($arr, "Have an arrayref");

Test::More::ok(
	scalar $o->perform(
		'methods' => ['attr3'],
		'values' => [$arr],
	),
	"Performed attr3"
);

Test::More::is($o->attr3, $arr, "attr3 contains arrayref");

Test::More::ok(
	scalar $o->perform(
		'methods' => ['attr3'],
		'values' => [$arr],
		'dereference' => ['attr3'],
	),
	"Performed attr3 with de-reference"
);

Test::More::is($o->attr3, 'a', "attr3 contains first element of arrayref");

Test::More::ok(
	scalar $o->perform(
		'methods' => ['attr2', 'attr3'],
		'values' => [$arr, $arr],
		'dereference' => ['attr2'],
	),
	"Performed attr3 with de-reference"
);

Test::More::is($o->attr2, 'a', "attr2 contains first element of arrayref");
Test::More::is($o->attr3, $arr, "attr3 contains arrayref");
};
{#line 4104 stack_trace
sub tracer {
	return Basset::Object->stack_trace;
};

Test::More::ok(tracer(), "Got a stack trace");
my $trace = tracer();
Test::More::ok($trace, "Has a stack trace");
Test::More::like($trace, qr/Package:/, "Contains word: 'Package:'");
Test::More::like($trace, qr/Filename:/, "Contains word: 'Filename:'");
Test::More::like($trace, qr/Line number:/, "Contains word: 'Line number:'");
Test::More::like($trace, qr/Subroutine:/, "Contains word: 'Subroutine:'");
Test::More::like($trace, qr/Has Args\? :/, "Contains word: 'Has Args:'");
Test::More::like($trace, qr/Want array\? :/, "Contains word: 'Want array:'");
Test::More::like($trace, qr/Evaltext:/, "Contains word: 'Evaltext:'");
Test::More::like($trace, qr/Is require\? :/, "Contains word: 'Is require:'");
};
{#line 4156 no_op
Test::More::ok(Basset::Object->no_op, "No op");
Test::More::is(Basset::Object->no_op, 1, "No op is 1");
my $obj = Basset::Object->new();
Test::More::ok($obj, "Got object");
Test::More::ok($obj->no_op, "Object no ops");
Test::More::is($obj->no_op, 1, "Object no op is 1");
};
{#line 4180 system_prefix
Test::More::is(Basset::Object->system_prefix(), '__b_', 'expected system prefix');
};
{#line 4211 privatize
Test::More::ok(! Basset::Object->privatize, 'Cannot privatize w/o method');
Test::More::is(Basset::Object->errcode, "BO-24", "proper error code");

Test::More::is(Basset::Object->privatize('foo'), '__b_foo', "privatized foo");
Test::More::is(Basset::Object->privatize('__b_foo'), '__b_foo', "__b_foo remains __b_foo");
};
{#line 4247 deprivatize
Test::More::ok(! Basset::Object->deprivatize, 'Cannot deprivatize w/o method');
Test::More::is(Basset::Object->errcode, "BO-25", "proper error code");

Test::More::is(Basset::Object->deprivatize('foo'), 'foo', "deprivatized foo");
Test::More::is(Basset::Object->deprivatize('__b_foo'), 'foo', "deprivatized __b_foo");
};
{#line 4278 deprivatize
Test::More::ok(! Basset::Object->is_private, 'Cannot is_private w/o method');
Test::More::is(Basset::Object->errcode, "BO-26", "proper error code");

Test::More::ok(! Basset::Object->is_private('foo'), 'foo is not private');
Test::More::ok(Basset::Object->is_private('__b_foo'), '__b_foo is private');
};
{#line 4329 cast
package Basset::Test::Testing::Basset::Object::cast::Subclass1;
our @ISA = qw(Basset::Object);

package Basset::Object;

#pretend it was loaded normally
$INC{Basset::Object->module_for_class("Basset::Test::Testing::Basset::Object::cast::Subclass1")}++;

my $subclass = "Basset::Test::Testing::Basset::Object::cast::Subclass1";

Test::More::ok(! Basset::Object->cast, "Cannot cast classes");
Test::More::is(Basset::Object->errcode, "BO-21", "proper error code");

my $o = Basset::Object->new();
Test::More::ok($o, "got object");

Test::More::ok(! $o->cast, "Cannot cast w/o class");
Test::More::is($o->errcode, "BO-22", "proper error code");
my $c = $o->cast($subclass, 'copy');
Test::More::ok($c, "casted object");
Test::More::is($o->pkg, "Basset::Object", "original part of super package");
Test::More::is($c->pkg, $subclass, "casted object part of sub package");
Test::More::is($c->errcode, $o->errcode, "error codes match, rest is assumed");

my $o2 = Basset::Object->new();
Test::More::ok($o2, "got object");

Test::More::ok(! $o2->cast, "Cannot cast w/o class");
Test::More::is($o2->errcode, "BO-22", "proper error code");
my $c2 = $o2->cast($subclass, 'copy');
Test::More::ok($c2, "casted object");
Test::More::is($o2->pkg, "Basset::Object", "original part of super package");
Test::More::is($c2->pkg, $subclass, "casted object part of sub package");
Test::More::is($c2->errcode, $o->errcode, "error codes match, rest is assumed");
};
{#line 4430 errortranslator
my $uses_real = Basset::Object->use_real_errors();
Test::More::is(Basset::Object->use_real_errors(0), 0, "Uses real errors");

my $translator = {
	'test error' => 'test message'
};

Test::More::ok($translator, "Created translator");
Test::More::is(Basset::Object->errortranslator($translator), $translator, "Set translator");
Test::More::is(scalar Basset::Object->error('test error', 'test code'), undef, "Set error");
Test::More::is(Basset::Object->usererror(), 'test message', 'Re-wrote error message');

Test::More::is(Basset::Object->errortranslator($uses_real), $uses_real, 'Class reset uses real error');
};
{#line 4462 use_real_errors
my $translator = Basset::Object->errortranslator();
Test::More::ok(Basset::Object->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2'
	}),
	'Class set error translator'
);

my $uses_real = Basset::Object->use_real_errors();

my $confClass = Basset::Object->pkg_for_type('conf');
Test::More::ok($confClass, "Got conf");

my $cfg = $confClass->conf;
Test::More::ok($cfg, "Got configuration");

Test::More::ok($cfg->{"Basset::Object"}->{'use_real_errors'} = 1, "enables real errors");

Test::More::is(scalar Basset::Object->error("extra error", "test code"), undef, "Class sets error");
Test::More::is(Basset::Object->usererror(), "extra error...with code (test code)", "Class gets literal error for literal");

Test::More::is(scalar Basset::Object->error(["formatted test error %d", 7], "test code"), undef, "Class sets formatted error");
Test::More::is(Basset::Object->usererror(), "formatted test error 7...with code (test code)", "Class gets literal error for formatted string");

Test::More::is(scalar Basset::Object->error(["formatted test error %d", 9], "test code"), undef, "Class sets formatted error");
Test::More::is(Basset::Object->usererror(), "formatted test error 9...with code (test code)", "Class gets literal error for string format");

Test::More::is(scalar Basset::Object->error("Some test error", "test code"), undef, "Class sets standard error");
Test::More::is(Basset::Object->usererror(), "Some test error...with code (test code)", "Class gets literal error for error code");

Test::More::is(scalar Basset::Object->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
Test::More::is(Basset::Object->usererror(), "Some unknown error...with code (unknown code)", "Class gets no user error");

Test::More::ok(Basset::Object->errortranslator(
	{
		'test code' => "friendly test message",
		'formatted test error %d' => "friendlier test message",
		'formatted test error 7' => 'friendliest test message',
		'extra error' => 'friendliest test message 2',
		'*' => 'star error',
	}),
	'Class changed error translator'
);

Test::More::is(scalar Basset::Object->error("Some unknown error", "unknown code"), undef, "Class sets standard error w/o translation");
Test::More::is(Basset::Object->usererror(), "Some unknown error...with code (unknown code)", "Class gets literal star error");

Test::More::is(Basset::Object->errortranslator($translator), $translator, 'Class reset error translator');
#Test::More::is(Basset::Object->errortranslator($uses_real), $uses_real, 'Class reset uses real error');
#Test::More::ok('foo', 'bar');
Test::More::is($cfg->{"Basset::Object"}->{'use_real_errors'} = $uses_real, $uses_real, "enables reset uses real errors");
};
{#line 4543 delegate
my $o = Basset::Object->new();
Test::More::ok($o, "Set up object");
my $o2 = Basset::Object->new();
Test::More::ok($o2, "Set up second object");
Test::More::ok(! scalar Basset::Object->delegate($o), "Class cannot set delegate");
Test::More::is(scalar $o->delegate($o2), $o2, "Object set delegate");
Test::More::is(scalar $o->delegate(), $o2, "Object accessed delegate");
Test::More::is(scalar $o->delegate(undef), undef, "Object deleted delegate");
};
{#line 4576 types
Test::More::ok(Basset::Object->types, "Got types out of the conf file");
my $typesbkp = Basset::Object->types();
my $newtypes = {%$typesbkp, 'testtype1' => 'Basset::Object', 'testtype2' => 'boguspkg'};
Test::More::ok($typesbkp, "Backed up the types");
Test::More::is(Basset::Object->types($newtypes), $newtypes, "Set new types");
Test::More::is(Basset::Object->pkg_for_type('testtype1'), 'Basset::Object', "Got class for new type");
Test::More::ok(! scalar Basset::Object->pkg_for_type('testtype2'), "Could not access invalid type");
Test::More::is(Basset::Object->types($typesbkp), $typesbkp, "Re-set original types");
};
{#line 4619 restrictions
package Basset::Test::Testing::Basset::Object::restrictions::subclass1;
our @ISA = qw(Basset::Object);

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::restrictions::subclass1->isa('Basset::Object'), 'proper subclass');
my $restrictions = {
	'foo' => [
		'a' => 'b'
	]
};
Test::More::ok($restrictions, 'made restrictions');
Test::More::is(Basset::Test::Testing::Basset::Object::restrictions::subclass1->restrictions($restrictions), $restrictions, 'added restrictions');
Test::More::is(Basset::Test::Testing::Basset::Object::restrictions::subclass1->restrictions, $restrictions, 'accessed restrictions');
};
{#line 4643 applied_restrictions
package Basset::Test::Testing::Basset::Object::applied_restrictions::Subclass;
our @ISA = qw(Basset::Object);

my %restrictions = (
	'specialerror' => [
		'error' => 'error3',
		'errcode' => 'errcode3'
	],
	'invalidrestriction' => [
		'junkymethod' => 'otherjunkymethod'
	]
);

Basset::Object->add_class_attr('e3');
Basset::Object->add_class_attr('c3');

Test::More::is(Basset::Object->e3(0), 0, "set e3 to 0");
Test::More::is(Basset::Object->c3(0), 0, "set c3 to 0");

sub error3 {
	my $self = shift;
	$self->e3($self->e3 + 1);
	return $self->SUPER::error(@_);
}

sub errcode3 {
	my $self = shift;
	$self->c3($self->c3 + 1);
	return $self->SUPER::errcode(@_);
}

Test::More::ok(scalar Basset::Test::Testing::Basset::Object::applied_restrictions::Subclass->add_restrictions(%restrictions), "Added restrictions to subclass");

package Basset::Object;

Test::More::ok(Basset::Test::Testing::Basset::Object::applied_restrictions::Subclass->isa('Basset::Object'), 'Proper subclass');
my $subclass = Basset::Test::Testing::Basset::Object::applied_restrictions::Subclass->restrict('specialerror');
Test::More::ok($subclass, "Restricted error");
Test::More::ok(! scalar $subclass->add_restricted_method('invalidrestriction', 'junkymethod'), "Could not add invalid restriction");
Test::More::ok($subclass->restricted, "Subclass is restricted");

Test::More::ok($subclass->applied_restrictions, "Subclass has applied restrictions");
my $restrictions = $subclass->applied_restrictions;

Test::More::ok(ref $restrictions eq 'ARRAY', 'applied restrictions are an array');
Test::More::is(scalar @$restrictions, 1, "Subclass has 1 restriction");
Test::More::is($restrictions->[0], 'specialerror', 'Correct restriction in place');
};
{#line 4708 restricted
package Basset::Test::Testing::Basset::Object::restricted::Subclass1;
our @ISA = qw(Basset::Object);

package Basset::Object;

Test::More::ok(! Basset::Object->restricted, "Basset::Object is not restricted");
Test::More::ok(! Basset::Test::Testing::Basset::Object::restricted::Subclass1->restricted, "Subclass is not restricted");
my $subclass = Basset::Object->inline_class;
Test::More::ok($subclass, "Subclassed Basset::Object");
my $subclass2 = Basset::Test::Testing::Basset::Object::restricted::Subclass1->inline_class();
Test::More::ok($subclass2, "Restricted Basset::Test::Testing::Basset::Object::restricted::Subclass1");
Test::More::ok($subclass->restricted, "Subclass is restricted");
Test::More::ok($subclass2->restricted, "Subclass is restricted");
};
{#line 4772 exceptions
my $confClass = Basset::Object->pkg_for_type('conf');
Test::More::ok($confClass, "Got conf");

my $cfg = $confClass->conf;
Test::More::ok($cfg, "Got configuration");

my $exceptions = $cfg->{"Basset::Object"}->{'exceptions'};

Test::More::is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0, "disables exceptions");
Test::More::is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0, "enables exceptions");
Test::More::is($cfg->{"Basset::Object"}->{'exceptions'} = $exceptions, $exceptions, "reset exceptions");
};
{#line 4801 last_exception
my $o = Basset::Object->new();
Test::More::ok($o, "Got object");

my $confClass = Basset::Object->pkg_for_type('conf');
Test::More::ok($confClass, "Got conf");

my $cfg = $confClass->conf;
Test::More::ok($cfg, "Got configuration");

Test::More::ok($cfg->{"Basset::Object"}->{'exceptions'} = 1, "enables exceptions");

Test::More::ok(scalar Basset::Object->wipe_errors, "Wiped out errors");
Test::More::ok(! Basset::Object->last_exception, "Last exception is empty");
eval {
	Basset::Object->error('test exception', 'test code');
};
Test::More::like($@, "/test code/", "Thrown exception matches");
Test::More::like(Basset::Object->last_exception, qr/test exception/, "Last exception matches");
Test::More::like($o->last_exception, qr/test exception/, "Object last exception matches");
Test::More::is($cfg->{"Basset::Object"}->{'exceptions'} = 0, 0,"disables exceptions");
};
