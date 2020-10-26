#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;

use Ask qw(:all);
use XML::LibXML 2;

sub search_person {
	my ($xml, $search_string) = @_;
	
	my @results = $xml->findnodes(qq{//person[contains(name/text(), "$search_string")]});
	
	if (@results == 0) {
		error("Cannot find '$search_string'\n");
		die;
	}
	
	if (@results == 1) {
		return $results[0];
	}
	
	my $i = 0;
	my @choices = map { [$i++, $_->findvalue('name')] } @results;
	
	return $results[ single_choice("Multiple results", choices => \@choices) ];
}

my $xml     = XML::LibXML->load_xml(IO => \*DATA);
my $person  = search_person($xml, entry("Who are you looking for?"));
my $address = join q[; ], map { $_->textContent } $person->findnodes(qq{adr/*});

info($address, title => $person->findvalue('name'));

__DATA__
<contacts>
	<person>
		<name>Barack Obama</name>
		<adr>
			<street-address>1600 Pennsylvania Avenue Northwest</street-address>
			<locality>Washington</locality>
			<region>DC</region>
			<postal-code>20500</postal-code>
			<country>United States</country>
		</adr>
	</person>
	<person>
		<name>David Cameron</name>
		<adr>
			<street-address>10 Downing Street</street-address>
			<locality>London</locality>
			<postal-code>SW1A 2AA</postal-code>
			<country>United Kingdom</country>
		</adr>
	</person>
</contacts>
