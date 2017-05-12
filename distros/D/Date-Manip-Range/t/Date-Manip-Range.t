use 5.14.0;
use warnings;

use Date::Manip;
use Test::More;


BEGIN { use_ok 'Date::Manip::Range' }

subtest 'new' => sub {
	subtest 'No parameters' => sub {
		my $object = new_ok( 'Date::Manip::Range' );
		ok( !$object->is_valid, 'Not valid' );
		is( $object->error, '', 'No error' );
	};

	my $object = new_ok( 'Date::Manip::Range', [{
		parse => '2015-01-01 to 2015-04-01'
	}] );
	ok( $object->is_valid, 'Parses range string' );
};

subtest 'parse' => sub {
	my $object = Date::Manip::Range->new( {date_format => '%Y-%m-%d'} );
	
	subtest 'Range operators' => sub {
		$object->parse( '2015-01-01 through 2015-04-01' );
		ok( $object->is_valid, 'through' );

		$object->parse( '2015-01-01 thru 2015-04-01' );
		ok( $object->is_valid, 'thru' );

		$object->parse( '2015-01-01 to 2015-04-01' );
		ok( $object->is_valid, 'to' );

		$object->parse( '2015-01-01 - 2015-04-01' );
		ok( $object->is_valid, '-' );

		$object->parse( '2015-01-01 ... 2015-04-01' );
		ok( $object->is_valid, '...' );

		$object->parse( '2015-01-01 .. 2015-04-01' );
		ok( $object->is_valid, '..' );

		$object->parse( 'between 2015-01-01 and 2015-04-01' );
		ok( $object->is_valid, 'between/and' );

		$object->parse( '2015-01-01 and 2015-04-01' );
		ok( $object->is_valid, 'and' );

		$object->parse( 'from 2015-01-01 through 2015-04-01' );
		ok( $object->is_valid, 'from/through' );

		$object->parse( 'from 2015-01-01 thru 2015-04-01' );
		ok( $object->is_valid, 'from/thru' );

		$object->parse( 'from 2015-01-01 to 2015-04-01' );
		ok( $object->is_valid, 'from/to' );
	};

	subtest 'Invalid ranges' => sub {
		$object->parse( '2015-01-01 invalid 2015-04-01' );
		ok( !$object->is_valid, 'Invalid operator' );

		$object->parse( '2015-04-01 to 2015-01-01' );
		ok( !$object->is_valid, 'Dates in reverse order' );

		$object->parse( 'from April 2015' );
		ok( !$object->is_valid, 'Prefix and no operator' );
	};

	subtest 'Implicit range' => sub {
		$object->parse( '2015-01-01 to 2015-04-01' );
		ok( !$object->is_implicit, 'Explicit' );

		subtest 'Month' => sub {
			$object->parse( 'April 2015' );
			ok( $object->is_valid, 'Successfully parsed' );
			ok( $object->is_implicit, 'Implicit' );
			is( $object->granularity, '1 month', 'Correct granularity' );
			is( $object->printf( '%Y-%m-%d', '%s to %s' ), 
				'2015-04-01 to 2015-04-30', 'Correct dates' );
		};
		
		subtest 'Year' => sub {
			$object->parse( '2015' );
			$object->format( '%s to %s' );
			ok( $object->is_valid, 'Successfully parsed' );
			ok( $object->is_implicit, 'Implicit' );
			is( $object->granularity, '1 year', 'Correct granularity' );
			is( $object->printf( '%Y-%m-%d', '%s to %s' ), 
				'2015-01-01 to 2015-12-31', 'Correct dates' );
		};
	};

	subtest 'Implicit start/end' => sub {
		subtest 'Month to Month' => sub {
			$object->parse( 'April 2015 to May 2015' );
			ok( $object->is_valid, 'Successfully parsed' );
			is( $object->printf( '%Y-%m-%d' ), '2015-04-01 to 2015-05-31', 
				'Correct dates' );
		};
		
		subtest 'Year to Year' => sub {
			$object->parse( '2012 to 2015' );
			ok( $object->is_valid, 'Successfully parsed' );
			is( $object->printf( '%Y-%m-%d' ), '2012-01-01 to 2015-12-31', 
				'Correct dates' );
		};
		
		subtest 'Year to Month' => sub {
			$object->parse( '2013 to May 2015' );
			ok( $object->is_valid, 'Successfully parsed' );
			is( $object->printf( '%Y-%m-%d' ), '2013-01-01 to 2015-05-31', 
				'Correct dates' );
		};
		
		subtest 'Month to Year' => sub {
			$object->parse( 'April 2014 to 2015' );
			ok( $object->is_valid, 'Successfully parsed' );
			is( $object->printf( '%Y-%m-%d' ), '2014-04-01 to 2015-12-31', 
				'Correct dates' );
		};
		
		subtest 'Format as shortest range' => sub {
			$object->parse( '2013 to May 2015' );
			is( $object->printf, 'January 2013 to May 2015', 'Year and month' );

			$object->parse( '2013 to May 3, 2015' );
			is( $object->printf, 'January 01, 2013 to May 03, 2015', 'Year and day' );

			$object->parse( 'June 2013 to May 7, 2015' );
			is( $object->printf, 'June 01, 2013 to May 07, 2015', 'Month and day' );
		};
		
		$object->parse( 'from April 2015' );
		ok( !$object->is_valid, 'Prefix and no operator' );
	};

	$object->parse( 'invalid' );
	$object->parse( '2015-01-01 to 2015-04-01' );
	ok( $object->is_valid, '"error" cleared' );
};

subtest 'includes' =>  sub {
	my $object = Date::Manip::Range->new( {parse => '2015-04-01 through 2015-05-01'} );

	ok( $object->includes( '2015-04-15' ), 'In range' );
	ok( !$object->includes( '2015-03-15' ), 'Before range' );
	ok( !$object->includes( '2015-06-15' ), 'After range' );
	ok( $object->includes( '2015-04-01' ), 'Start date included' );
	ok( $object->includes( '2015-05-01' ), 'End date included' );

	subtest 'Exclusive range' => sub {
		subtest '"start" exclusive' => sub {
			$object->include_end( 1 );
			$object->include_start( 0 );
			ok( !$object->includes( '2015-04-01' ), 'Start date excluded' );
			ok( $object->includes( '2015-05-01' ), 'End date included' );
		};

		subtest '"end" exclusive' => sub {
			$object->include_end( 0 );
			$object->include_start( 1 );
			ok( $object->includes( '2015-04-01' ), 'Start date included' );
			ok( !$object->includes( '2015-05-01' ), 'End date excluded' );
		};

		subtest 'Both exclusive' => sub {
			$object->include_end( 0 );
			$object->include_start( 0 );
			ok( !$object->includes( '2015-04-01' ), 'Start date excluded' );
			ok( !$object->includes( '2015-05-01' ), 'End date excluded' );
		};
	};

	$object->includes( 'invalid' );
	ok( !$object->is_valid, 'Check an invalid date' );
	$object->includes( '2015-04-15' );
	ok( $object->is_valid, '"error" cleared' );
};

subtest 'printf' => sub {
	my $object = Date::Manip::Range->new;
	
	subtest 'Explicit range' => sub {
		$object->parse( '2015-04-01 to 2015-05-01' );
		is( $object->printf, 'April 01, 2015 to May 01, 2015', 'Default format' );

		$object->parse( '2015-04-01 thru 2015-05-01' );
		is( $object->printf, 'April 01, 2015 thru May 01, 2015', 'Same operator' );

		$object->parse( 'from 2015-04-01 through 2015-05-01' );
		is( $object->printf, 'from April 01, 2015 through May 01, 2015', 'With prefix' );
	};
	
	$object->parse( 'April 2015' );
	is( $object->printf, 'April 2015', 'Implicit range' );

	$object->parse( 'April 2015' );
	is( $object->printf( '%Y-%m' ), '2015-04', 'Different date format' );

	$object->parse( 'April 2015' );
	is( $object->printf( undef, 'See %s' ), 'See April 2015', 'Different output format' );
};

subtest 'adjust' => sub {
	my $object = Date::Manip::Range->new( {parse => '2015-01-01 to 2015-04-01'} );
	
	$object->adjust( '2 months' );
	ok( $object->is_valid, 'Normal' );
		
	$object->adjust( 'invalid' );
	ok( !$object->is_valid, 'Invalid' );

	$object->adjust( '' );
	ok( !$object->is_valid, 'Blank' );

	$object->adjust( undef );
	ok( !$object->is_valid, 'No delta' );
	$object->includes( '2 months' );
	ok( $object->is_valid, '"error" cleared' );

	subtest 'Frequencies' => sub {
		$object->adjust( 'annual' );
		ok( $object->is_valid, 'annual' );

		$object->adjust( 'monthly' );
		ok( $object->is_valid, 'monthly' );

		$object->adjust( 'weekly' );
		ok( $object->is_valid, 'weekly' );

		$object->adjust( 'daily' );
		ok( $object->is_valid, 'daily' );
	};

	subtest 'Dates changed' => sub {
		my $object = Date::Manip::Range->new( {parse => 'January 2015 to April 2015'} );

		$object->adjust( '2 months' );
		is( $object->printf, 'March 2015 to June 2015', 'Addition' );

		$object->adjust( '-2 months' );
		is( $object->printf, 'January 2015 to April 2015', 'Subtraction' );
	};
};

done_testing();
