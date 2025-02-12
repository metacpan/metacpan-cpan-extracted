#!/usr/bin/perl

use Test::More;

my $class = 'Chemistry::Elements';
my $method = 'Z';
my @methods = qw(Z symbol name error);

subtest 'sanity' => sub {
	use_ok $class;
	ok defined &{"${class}::can"}, "$class defines its own can";
	};

subtest 'new object' => sub {
	my $symbol = 'U';

	my $element = $class->new( $symbol );
	isa_ok $element, $class ;
	ok $element->can($method), "Object can call the $method method";
	can_ok $element, @methods;

	subtest 'read values' => sub {
		is $element->$method(),   92,       "Got right Z for $symbol";
		is $element->symbol,     $symbol,   "Got right symbol for $symbol";
		is $element->name,       'Uranium', "Got right name for $symbol (Default)";
		};

	subtest 'change element' => sub {
		my $symbol = 'Pu';
		is $element->$method(94),   94,   "Got right Z for $symbol after U decay";
		is $element->symbol, $symbol,     "Got right symbol for $symbol";
		is $element->name,   'Plutonium', "Got right name for $symbol (Default)";
		};

	subtest 'change to nonsense' => sub {
		my @table = (
			[ qw(Pa symbol) ],
			[ qw(Technetium name) ],
			[ '', 'empty string' ],
			[ undef, 'undef' ],
			[ 0, 'out of range (0)' ],
			[ 200, 'out of range (200)' ],
			[ -1,  'out of range (-1)' ],
			);

		foreach my $row ( @table ) {
			my( $arg, $label ) = @$row;
			subtest $label => sub {
				ok ! $element->$method($arg), "Could not change Z to $label";
				like $element->error, qr/\Q$arg\E is not a valid proton/,   "error notes invalid argument";
				};
			}
		};
	};

done_testing();
