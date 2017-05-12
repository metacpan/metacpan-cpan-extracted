#!/usr/bin/perl

use strict;
no warnings 'once';
use Test::More tests => 3;

package ScoobyCollection;
use base qw(Class::Tangram);
our $fields = {
    hash => {
       scoobies => {
          class => "Scooby",
          companion => "collection"
       }
    }
};
package Scooby;
use base qw(Class::Tangram);
our $fields = {
    string => [ qw(name) ],
    ref => {
        collection => {
            class => "ScoobyCollection",
            companion => "scoobies",
	},
    },
};

# if inserting stuff into a hash collection, without specifying a hash
# key, then it looks for a method called `collection_hek' for the
# index
sub scoobies_hek {
    return (shift)->name;
}

use Data::Dumper;
use Set::Object qw(blessed);

sub set_name {
    my $self = shift;
    if (my $c = $self->collection) {
	my $new_name = shift;

	# This hack is the fastest implementation ATM
	$c->set_scoobies(map { (blessed $_ || $_ ne $self->{name})
				   ? $_ : $new_name }
			 $c->scoobies_pairs);
	$self->{name} = $new_name;

	# This code looks cleaner but is slower with the current
	# implementation
	#$c->scoobies_remove($self);
	#$self->{name} = shift;
	#$c->scoobies_insert($self);

    } else {
	$self->{name} = shift;
    }
}

package main;

my @scoobies = ( Scooby->new(name => "Buffy"),
		 Scooby->new(name => "Willow"),
		 Scooby->new(name => "Giles") );

my $snacks = new ScoobyCollection;

$snacks->scoobies_insert(@scoobies);

is( $snacks->scoobies("Buffy"), $scoobies[0],
    "Auto-indexing works!" );

use Data::Dumper;
is_deeply( { $snacks->scoobies_pairs },
	   { map { $_->name => $_ } @scoobies },
	   "_pairs_X_hash" );

$scoobies[0]->set_name("Foobar");

#print Dumper $snacks->scoobies;

is( $snacks->scoobies("Foobar"), $scoobies[0],
    "Re-Auto-indexing works!" );
