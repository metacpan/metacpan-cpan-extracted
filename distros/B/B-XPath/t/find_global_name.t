#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;

use_ok( 'B::XPath' );
use YAML;

my $tests =
[
	{
		expression => q|//gvsv[@NAME='foo']|,
		matches    =>
		[
			{
				NAME => 'foo',
				find_file => $0,
				find_line => 'foo',
			},
			{
				NAME => 'foo',
				find_file => $0,
				find_line => 'fooi',
			},
		],
	},
	{
		expression => q|//gvsv|,
		matches    =>
		[
			{
				NAME => 'foo',
				find_file => $0,
				find_line => 'foo',
			},

			# this occurs after the foo interpolation in the code
			# but not as deeply in the optree -- so it comes first here
			{
				NAME => 'bar',
				find_file => $0,
				find_line => 'bar',
			},
			{
				NAME => 'foo',
				find_file => $0,
				find_line => 'fooi',
			},
		],
	}
];

use vars qw( $foo $bar );

my %lines = 
(
	foo  => __LINE__ + 8,
	fooi => __LINE__ + 8,
	bar  => __LINE__ + 8,
);

sub some_sub
{
	my $x        = shift;
	$foo         = $x;
	print "\$x is $x\n\$foo is $foo\n";
	$bar  = $x * 2;
}

my $node = B::XPath->fetch_root( \&some_sub );

for my $test (@$tests)
{
	for my $match ( $node->match( $test->{expression} ) )
	{
		warn "Out of matches!\n" unless @{ $test->{matches} };
		my $match_test = shift @{ $test->{matches} };
		is( $match->NAME(), $match_test->{NAME},
		    "GV found with right name $match_test->{NAME}" );
		is( $match->get_file(), $match_test->{find_file},
		    '... in correct file' );
		is( $match->get_line(), $lines{ $match_test->{find_line} },
			'... and on proper line' );
	}
}
