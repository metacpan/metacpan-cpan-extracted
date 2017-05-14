
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 1 };

use Class::Maker qw(:all);

use Class::Maker::Examples;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

use strict;

use Data::Dumper;

use IO::Extended qw(:all);

	println "\nFinishing class definition.\n\n\nStarting testing\n";

	ind 1;

	println "\nInstantiate Human...";

		# Object Human

	my $human = new Human(

		firstname => 'Adam',

		lastname => 'NoName',

		eye_color => 'green',

		hair_color => 'black',

		nicknames => [qw( TheDuke JohnDoe )],

		contacts => { Peter => 'peter@anywhere.de' },

		telefon => { Phone => '01230230', Fax => '0237923487' },
	);

	push @{ $human->nicknames }, qw( Maniac TwistedBrain );

	$human->telefon->{Mobil} = '0123823727';

	foreach my $key ( keys %{ $human->telefon } )
	{
		::ind 1;

		::printfln "Telefon: %20s (%s)\n", $key, $human->telefon->{$key};
	}

	$human->firstname = 'Adam!';

	$human->_driverslicense( '12-12-80' );

	println "Instantiate Employee...";

		# Object Employee

	my $employee = new Employee(

		firstname => 'Fred',

		lastname => 'Firestone',

		eye_color => 'brown',

		hair_color => 'black',

		income => '100 rockdollar/year',

		payment => 'monthly',

		position => 'assistant',

		friends => [qw( Peter Lora John )],
	);

	$employee->eye_color = 'something like '.$employee->eye_color;

	$employee->Employee::firstname( 'employee_name' );

	#debugSymbols( 'main::Human::' );

	$employee->_dummy1;

	#$employee->dummy1;

	println "human eyecolor: ", $human->hair_color;

	foreach my $class ( qw( Human Employee Customer User ) )
	{
		print Dumper Class::Maker::Reflection::reflect( $class );
	}

	$Class::Maker::Basic::Constructor::DEBUG = 1;

	printfln "TRAVERSING ISA: %s", join( ', ', @{ Class::Maker::Reflection::inheritance_isa( 'Employee' ) } );

	our $loaded = 1;

	print "ok 1\n";

END { print "not ok 1\n" unless $loaded; }
