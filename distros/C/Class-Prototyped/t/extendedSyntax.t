use strict;
$^W++;
use Class::Prototyped;
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 43;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

package main;

my $p = Class::Prototyped->new();

$p->reflect->addSlot('field_1' => 'field_1');
$p->reflect->addSlot([qw(field_2)] => 'field_2');
$p->reflect->addSlot([qw(field_3 FIELD)] => 'field_3');
$p->reflect->addSlot([qw(field_4 constant)] => 'field_4');
$p->reflect->addSlot([qw(field_5 constant 1)] => 'field_5');
$p->reflect->addSlot([qw(field_6 FIELD constant)] => 'field_6');
$p->reflect->addSlot([qw(field_7 FIELD constant 1)] => 'field_7');

$p->reflect->addSlot('method_1' => sub { print "method_1.\n";});
$p->reflect->addSlot([qw(method_2)] => sub { print "method_2.\n";});
$p->reflect->addSlot([qw(method_3 METHOD)] => sub { print "method_3.\n";});
$p->reflect->addSlot([qw(method_4 superable)] => sub { print "method_4.\n";});
$p->reflect->addSlot([qw(method_5 superable 1)] => sub { print "method_5.\n";});
$p->reflect->addSlot([qw(method_6 METHOD superable)] => sub { print "method_6.\n";});
$p->reflect->addSlot([qw(method_7 METHOD superable 1)] => sub { print "method_7.\n";});

my %slots = $p->reflect->getSlots(undef, 'rotated');

ok( join('|', sort keys %slots),
		join('|', sort map {("field_$_", "method_$_")} (1..7)) );

foreach my $i (1..3) {
	ok( Data::Dumper->Dump([$slots{"field_$i"}]),
			Data::Dumper->Dump([{attribs => {}, value => "field_$i", type => 'FIELD'}])
		);

	ok( Data::Dumper->Dump([$slots{"method_$i"}]),
			Data::Dumper->Dump([{attribs => {}, value => sub {}, type => 'METHOD'}])
		);
}

foreach my $i (4..7) {
	ok( Data::Dumper->Dump([$slots{"field_$i"}]),
			Data::Dumper->Dump([{attribs => {constant => 1}, value => "field_$i", type => 'FIELD'}])
		);

	ok( Data::Dumper->Dump([$slots{"method_$i"}]),
			Data::Dumper->Dump([{attribs => {superable => 1}, value => sub {}, type => 'METHOD'}])
		);
}

my $q = $p->clone();

$p->reflect->addSlot('parent_1*' => $q);
ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_1*)) );

$p->reflect->addSlot([qw(parent_2*)] => $q);
ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_1* parent_2*)) );

$p->reflect->addSlot([qw(parent_3* PARENT)] => $q);
ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_1* parent_2* parent_3*)) );

$p->reflect->addSlot([qw(parent_4* promote)] => $q);
ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_4* parent_1* parent_2* parent_3*)) );

$p->reflect->addSlot([qw(parent_5* promote 1)] => $q);
ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_5* parent_4* parent_1* parent_2* parent_3*)) );

$p->reflect->addSlot([qw(parent_6* PARENT promote)] => $q);
ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_6* parent_5* parent_4* parent_1* parent_2* parent_3*)) );

$p->reflect->addSlot([qw(parent_7* PARENT promote 1)] => $q);
ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_7* parent_6* parent_5* parent_4* parent_1* parent_2* parent_3*)) );

%slots = $p->reflect->getSlots(undef, 'rotated');

ok( join('|', sort keys %slots),
		join('|', sort map {("field_$_", "method_$_", "parent_$_*")} (1..7)) );

foreach my $i (1..7) {
	ok( Data::Dumper->Dump([$slots{"parent_$i*"}]),
			Data::Dumper->Dump([{attribs => {}, value => $q, type => 'PARENT'}])
		);
}

$p->reflect->addSlot(['field_d', description => 'This is a friendly to use field!'], 'friendly');
$p->reflect->addSlot(['method_d', description => 'This is a friendly to use method!'], sub {});
$p->reflect->addSlot(['parent_d*', description => 'This is a friendly to use parent!'], $q);

ok( join('|', $p->reflect->slotNames('PARENT')),
		join('|', qw(parent_7* parent_6* parent_5* parent_4* parent_1* parent_2* parent_3* parent_d*)) );

ok( Data::Dumper->Dump([[$p->reflect->getSlots(undef, 'rotated')]]),
		Data::Dumper->Dump([[
			(map {("parent_$_*" => {attribs => {}, type => 'PARENT', value => $q})} qw(7 6 5 4 1 2 3)),
			('parent_d*' => {attribs => {description => 'This is a friendly to use parent!'}, type => 'PARENT', value => $q}),
			(map {("field_$_" => {attribs => {}, type => 'FIELD', value => "field_$_"})} (1..3)),
			(map {("field_$_" => {attribs => {constant => 1}, type => 'FIELD', value => "field_$_"})} (4..7)),
			(map {("method_$_" => {attribs => {}, type => 'METHOD', value => scalar($p->reflect->getSlot("method_$_"))})} (1..3)),
			(map {("method_$_" => {attribs => {superable => 1}, type => 'METHOD', value => scalar($p->reflect->getSlot("method_$_"))})} (4..7)),
			(field_d => {attribs => {description => 'This is a friendly to use field!'}, type => 'FIELD', value => 'friendly'}),
			(method_d => {attribs => {description => 'This is a friendly to use method!'}, type => 'METHOD', value => sub {}}),
		]]) );

my $r = $p->clone();

ok( Data::Dumper->Dump([[$p->reflect->getSlots(undef, 'rotated')]]),
		Data::Dumper->Dump([[$r->reflect->getSlots(undef, 'rotated')]]) );

eval { $p->reflect->addSlot([qw(field_fail superable)], 'val'); };
ok( $@ =~ /FIELD slots cannot have the 'superable' attribute/ );

eval { $p->reflect->addSlot([qw(field_fail promote)], 'val'); };
ok( $@ =~ /FIELD slots cannot have the 'promote' attribute/ );

eval { $p->reflect->addSlot([qw(method_fail constant)], sub {}); };
ok( $@ =~ /METHOD slots cannot have the 'constant' attribute/ );

eval { $p->reflect->addSlot([qw(method_fail promote)], sub {}); };
ok( $@ =~ /METHOD slots cannot have the 'promote' attribute/ );

eval { $p->reflect->addSlot([qw(method_fail METHOD)], 'hi there'); };
ok( $@ =~ /method slots have to have CODE refs as values/ );

eval { $p->reflect->addSlot([qw(parent_fail* constant)], $q); };
ok( $@ =~ /PARENT slots cannot have the 'constant' attribute/ );

eval { $p->reflect->addSlot([qw(parent_fail* superable)], $q); };
ok( $@ =~ /PARENT slots cannot have the 'superable' attribute/ );

eval { $p->reflect->addSlot([qw(parent_fail PARENT)], $q); };
ok( $@ =~ /slots should end in \* if and only if the type is parent/ );

eval { $p->reflect->addSlot([qw(parent_fail* FIELD)], $q); };
ok( $@ =~ /slots should end in \* if and only if the type is parent/ );

eval { $p->reflect->addSlot([qw(parent_fail* METHOD)], sub {}); };
ok( $@ =~ /slots should end in \* if and only if the type is parent/ );


