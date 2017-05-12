#!/usr/bin/perl

use strict;
use warnings;

use Config::XPath;

my $config = Config::XPath->new( filename => "elements.xml" );

## Strings ##

my $hydrogen_symbol = $config->get_string( '//el[@name="hydrogen"]/@symbol' );
print "The symbol for hydrogen is $hydrogen_symbol\n";

my $C_name = $config->get_string( '//el[@symbol="C"]/@name' );
print "The name of the element 'C' is $C_name\n";

my $number_of_elements = $config->get_string( 'count(//el)' );
print "There are in total $number_of_elements elements in the file\n";

my $oxygen_state =
     $config->get_string( '//el[@name="oxygen"]/@state',
                          default => "gas" );
print "The STP state of oxygen is $oxygen_state\n";

## Structures ##

my $hydrogen = $config->get( { name   => '//el[1]/@name',
                               symbol => '//el[1]/@symbol' } );

print "$hydrogen->{name}'s symbol is $hydrogen->{symbol}\n";

$hydrogen = $config->get(
   [ '//el[1]/@oranges', '//el[1]/@name' ],
   default => [ undef, "name" ]
);

# $hydrogen is now [ undef, 'hydrogen' ]

my $tritium = $config->get(
   {
      name     => '//el[1]/isotope[3]/@name',
      halflife => '//el[1]/isotope[3]/halflife'
   },
   default => { halflife => "none" }
);

print "The halflife of $tritium->{name} is $tritium->{halflife}\n";

## Lists ##

my @element_names = $config->get_list( '//el/@name' );
print "The element names are:\n";
print "  $_\n" for @element_names;

# @element_names = $config->get_list( '//el', '@name' );
# Equivalent to the previous example

my @number_of_isotopes = $config->get_list( '//el', 'count(isotope)' );
print "Each element has:\n";
print "  $_ isotopes\n" for @number_of_isotopes;

my @iso = $config->get_list( '//el',
                             { name          => '@name',
                               first_isotope => 'isotope[1]/@number' } );
print "$_->{name} has an isotope $_->{first_isotope}\n" for @iso;

my @hydrogen_halflives = $config->get_list(
   '//el[@name="hydrogen"]/isotope',
   { number => '@number', value => 'halflife', unit => 'halflife/@unit' },
   default => { unit => 'forever', value => '0' }
);
print "Hydrogen has isotopes of halflives:\n";
print "  $_->{number} has: $_->{value} $_->{unit}\n" for @hydrogen_halflives;

## Mappings ##

my $symbols = $config->get_map( '//el', '@name', '@symbol' );
print "The symbol for carbon is $symbols->{carbon}\n";

## Subconfigurations ##

my $oxygen_config = $config->get_sub( '//el[@name="oxygen"]' );

my $oxygen_symbol = $oxygen_config->get_string( '@symbol' );
print "The symbol for oxygen is $oxygen_symbol\n";

my $n_isotopes    = $oxygen_config->get_string( 'count(isotope)' );
print "Oxygen has $n_isotopes isotopes\n";

my @isotopes = $oxygen_config->get_list( 'isotope/@number' );
print "  $_\n" for @isotopes;

my $abundances = $oxygen_config->get_map(
                    'isotope',
                    '@number', '@NA',
                    default => 'trace' );
print "Their natural abundances are:\n";
print "  $_: $abundances->{$_}\n" for sort keys %$abundances;

## Subconfiguration lists ##

foreach my $element_config ( $config->get_sub_list( '//el' ) ) {
   my $name  = $element_config->get_string( '@name' );
   my $state = $element_config->get_string( '@state',
                                            default => "gas" );
   print "$name is a $state at STP\n";
}
