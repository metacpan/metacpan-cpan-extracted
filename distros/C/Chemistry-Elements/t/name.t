#!/usr/bin/perl

#!/usr/bin/perl

use Test::More;

my $class = 'Chemistry::Elements';
my $method = 'name';
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
		is $element->Z,         92,        "Got right Z for $symbol";
		is $element->symbol,    $symbol,   "Got right symbol for $symbol";
		is $element->$method(), 'Uranium', "Got right name for $symbol (Default)";
		};

	subtest 'change element' => sub {
		my $symbol = 'Pu';
		is $element->Z(94),     94,          "Got right Z for $symbol after U decay";
		is $element->symbol,    $symbol,     "Got right symbol for $symbol";
		is $element->$method(), 'Plutonium', "Got right name for $symbol (Default)";
		};

	subtest 'change to nonsense' => sub {
		my @table = (
			[ qw(Te symbol) ],
			[ '',    'empty string' ],
			[ undef, 'undef' ],
			[ 0,     'number' ],
			[ 200,   'number' ],
			[ -1,    'number' ],
			);

		foreach my $row ( @table ) {
			my( $arg, $label ) = @$row;
			subtest $label => sub {
				ok ! $element->$method($arg), "Could not change name to $label";
				like $element->error, qr/\Q$arg\E is not a valid element name/,   "error notes invalid argument";
				};
			}
		};
	};

done_testing();
