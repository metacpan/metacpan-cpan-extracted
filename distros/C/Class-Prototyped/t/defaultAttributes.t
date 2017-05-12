use strict;
$^W++;
use Class::Prototyped qw(:NEW_MAIN);
use Data::Dumper;
use Test;

BEGIN {
	$|++;
	plan tests => 8;
}

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

my $p1 = new( a => 2, b => sub {'b'} );

ok( scalar(Class::Prototyped->reflect->_defaults),
		scalar($p1->reflect->_defaults) );

ok( scalar($p1->reflect->_defaults) ne scalar($p1->reflect->defaultAttributes) );

{
	my $temp = Data::Dumper->Dump([$p1->reflect->_defaults, $p1->reflect->_defaults]);
	ok( $temp =~ s/\$VAR1//g, 2);
}

{
	my $temp = Data::Dumper->Dump([$p1->reflect->_defaults, $p1->reflect->defaultAttributes]);
	ok( $temp =~ s/\$VAR1//g, 1);

	$temp = $p1->reflect->defaultAttributes;
	$temp->{METHOD}->{superable} = 1;
	$p1->reflect->defaultAttributes($temp);

	ok( scalar(Class::Prototyped->reflect->_defaults) ne
			scalar($p1->reflect->_defaults) );

	ok( Data::Dumper->Dump([Class::Prototyped->reflect->_defaults]),
			Data::Dumper->Dump([{ FIELD => undef, METHOD => undef, PARENT => undef }]) );

	ok( Data::Dumper->Dump([$p1->reflect->_defaults]),
			Data::Dumper->Dump([{ FIELD => undef, METHOD => {superable => 1}, PARENT => undef }]) );

	$p1->reflect->addSlot(c => sub {'c'});

	ok( Data::Dumper->Dump([[$p1->reflect->getSlots(undef, 'rotated')]]),
			Data::Dumper->Dump([[
					a => { attribs => {}, type => 'FIELD', value => 2 },
					b => { attribs => {}, type => 'METHOD', value => sub { } },
					c => { attribs => {superable => 1}, type => 'METHOD', value => sub { } }
				]]) );

}
