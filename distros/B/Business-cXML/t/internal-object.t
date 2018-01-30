#!perl -T
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Deep;

use XML::LibXML;
XML::LibXML->new()->load_catalog('t/xml-catalog/catalog.xml');

use XML::LibXML::Ferry;

# We cover:
use Business::cXML::Object;

use lib 't/';
use Test::MyObject;

plan tests => 16;

my $class = "Test::MyObject";
my $o;
my $d;

## Plain
#
$o = Test::MyObject->new();
isa_ok($o, 'Test::MyObject', 'Can create an object');
cmp_deeply(
	$o,
	noclass({
		_nodeName       => 'MyObject',
		mandatorystring => 'default',
		optionalstring  => undef,
		items           => [],
		inside          => undef,
	}),
	'Fresh object is as expected'
);

## With name
#
$o = Test::MyObject->new('AlternateName');
cmp_deeply($o->{_nodeName}, 'AlternateName', 'Can create with an alternate node name');

## From hash
#
$o = Test::MyObject->new({
	optionalstring => 'my option',
	ignorethis     => 'foobar',
	inside         => {},
});
isa_ok($o->inside, 'Business::cXML::Object', 'Can create sub-objects');
cmp_deeply(
	$o,
	noclass({
		_nodeName       => 'MyObject',
		mandatorystring => 'default',
		optionalstring  => 'my option',
		items           => [],
		inside          => { _nodeName => 'GenericNode' },
	}),
	'Can create object from hash'
);

## From XML
#
$d = XML::LibXML->load_xml(
	string => '<MyObject mandatoryString="string from node" optionalString="other string from node"><Item>foo</Item><Item>bar</Item></MyObject>'
)->documentElement;
$o = Test::MyObject->new($d);
isa_ok($o, 'Test::MyObject', 'Can create object from node');
cmp_deeply(
	$o,
	noclass({
		_nodeName       => 'MyObject',
		mandatorystring => 'string from node',
		optionalstring  => 'other string from node',
		items           => [ 'foo', 'bar' ],
		inside          => undef,
	}),
	'Object from node is as expected'
);

## copy()
#
$o->copy({
	_nodeName      => 'BrokenObject',
	ignorethis     => 'foobar',
	optionalstring => undef,
	items          => undef,
});
cmp_deeply(
	$o,
	noclass({
		_nodeName       => 'MyObject',
		mandatorystring => 'string from node',
		optionalstring  => undef,
		items           => undef,
		inside          => undef,
	}),
	'Copy from hash is limited to declared properties'
);

## Accessors
#
cmp_deeply($o->_nodeName(), 'MyObject', 'Node name access method');
cmp_deeply($o->mandatorystring, 'string from node', 'Normal access method');

eval { $o->non_existent(); };
ok($@, 'Non-existent access method fails');

eval { $class->foo(); };
ok($@, 'Access method on non-object fails');

## can()
#
ok($o->can('_nodeName'), 'Can _nodeName()');
ok($o->can('mandatorystring'), 'Can mandatorystring()');
ok(!$o->can('foo'), 'Cannot foo()');

## Destruction
#
cmp_deeply([ $o->DESTROY() ], [], 'Destruction');


