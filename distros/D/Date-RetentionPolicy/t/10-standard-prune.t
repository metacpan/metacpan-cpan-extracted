#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok( 'Date::RetentionPolicy' ) or BAIL_OUT;
my $epoch_2018= 1514764800;

my @tests= (
	{
		name   => 'daily from daily list',
		retain => [ { interval => { days => 1 }, history => { days => 10 } } ],
		dates  => [ map { $epoch_2018 - $_*24*60*60 } 1..5 ],
		keep   => [ map { $epoch_2018 - $_*24*60*60 } 1..5 ],
		reach  => .5,
	},
	{
		name   => 'daily from hourly list',
		retain => [ { interval => { days => 1 }, history => { days => 10 } } ],
		dates  => [ map { $epoch_2018 - $_*60*60 } 0..47 ],
		keep   => [ $epoch_2018, $epoch_2018 - 24*60*60, $epoch_2018 - 47*60*60 ],
		reach  => .5,
	}
);
for my $t (@tests) {
	subtest $t->{name} => sub {
		my $rp= new_ok( 'Date::RetentionPolicy', [ retain => $t->{retain}, reference_date => $epoch_2018, reach_factor => $t->{reach} ] );
		my @list= @{ $t->{dates} };
		$rp->prune(\@list);
		is_deeply( \@list, $t->{keep}, 'kept' );
	};
}

done_testing;