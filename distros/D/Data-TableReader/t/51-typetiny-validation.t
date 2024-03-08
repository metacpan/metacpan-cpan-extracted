#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use File::Spec::Functions 'catfile';
use Log::Any '$log';
use Log::Any::Adapter 'TAP', filter => 'warn';
use Data::TableReader;

plan skip_all => 'Requires Types::Standard to be installed'
	unless eval { require Types::Standard };

my $camelcase= Types::Standard::Str()
	->where(sub { /^[A-Z][a-z]*([0-9]|[A-Z][a-z]*)*\Z/ })
	->plus_coercions(Types::Standard::Str() => sub {
		(my $x= $_[0]) =~ s/_([a-z0-9])/uc($1)/ge;
		$x =~ s/^([a-z])/uc($1)/e;
		$x;
	});

subtest trim_validate_coerce => sub {
	my $tr= new_ok( 'Data::TableReader', [
			input => [
                           [ 'id', 'name   ', 'description' ],
                           [ '1 ', '   test', '' ],
                           [ '2',  'Test_2', 'Some details' ],
                           [ '3',  'test_three ', '  yada yada' ],
                           [ '4',  "can't coerce", '' ],
                           [ ' ',  'cant_coerce_id', '' ],
                        ],
			fields => [
				{ name => 'id', trim => 1, type => Types::Standard::Int() },
				{ name => 'name', trim => 1, type => $camelcase, coerce => 1 },
				{ name => 'description', trim => 1, type => Types::Standard::Maybe([Types::Standard::Str()]) },
			],
			on_validation_fail => sub {
				my ($reader, $failures, $values, $context)= @_;
				for (@$failures) {
					my ($field, $value_index, $message)= @$_;
					$values->[$value_index]= [ $values->[$value_index], $message ];
				}
				return 'use';
			},
			log => $log,
		], 'TableReader' );
	my $i= $tr->iterator;
	is_deeply( $i->all,
		[
			{ id => 1, name => 'Test', description => undef },
			{ id => 2, name => 'Test2', description => 'Some details' },
			{ id => 3, name => 'TestThree', description => 'yada yada' },
			{ id => 4, name => [ "can't coerce", q{Value "can't coerce" did not pass type constraint} ], description => undef },
			{ id => [ undef, q{Undef did not pass type constraint "Int"} ], name => 'CantCoerceId', description => undef },
		],
		'valid row' );
};

done_testing;
