#!/usr/bin/perl -w
package TestCode::GenerateCombos;

sub inherit_lists
{
	#generates lists like this:
	#(
	#['Inherit'],
	#['Inherit', 'Inherit'],
	#['Inherit', 'Inherit', 'Inherit'],
	#)
	#etc, up to the number of inherits you specify in the first argument.
	
	my $num = shift;
	
	my @inherits;
	
	for (1..$num)
	{
		push @inherits, [('Inherit') x $_];
	}
	
	return @inherits;
}

sub list_to_namespace
{
	#takes a list of parts of a namespace
	#joins them with the namespace separator.
	
	return join '::', @_;
}

sub lol_to_namespace
{
	my @return;
	
	foreach (@_)
	{
		push @return, list_to_namespace @$_;
	}
	
	return @return;
}

sub unlazy_combos
{
	#all the combinations of classes that do not involve lazy objects. Inheritance up to two levels deep.
	
	my $base = 'Simple::';
	
	my @combos = lol_to_namespace(inherit_lists(2));
	
	return map $base.$_, @combos;
}

use Data::Dumper;

print Dumper (unlazy_combos);