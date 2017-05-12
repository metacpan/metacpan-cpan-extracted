#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Visitor::Callback;

my $data = {
	type_a => {
		point => 50,
		subtype_a_2 => {
			point => 27,
			subtype_a_2_bar => {
				circle => 14,
			},
		},
	},
	point => 33,
};


my $sum = 0;

Data::Visitor::Callback->new(
	ignore_return_values => 1,
	hash_entry => sub {
		my ( $self, $k, $v ) = @_;
		$sum += $v unless ref $v;
	},
)->visit($data);

is($sum, 124, 'get_recursive_hash_value_visitor, all values');


$sum = 0;
Data::Visitor::Callback->new(
	ignore_return_values => 1,
	hash_entry => sub {
		my ( $self, $k, $v ) = @_;
		$sum += $v if $k eq 'point';
	},
)->visit($data);

is($sum, 110, 'get_recursive_hash_value_visitor, only "point" keys');

done_testing;
