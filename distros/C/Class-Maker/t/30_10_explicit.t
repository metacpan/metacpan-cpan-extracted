use Test::More qw(no_plan);

use strict;

use warnings;

use IO::Extended qw(:all);

use Data::Dump qw(dump);

use Class::Maker qw(class);

BEGIN
  {
	$Class::Maker::explicit = 1;
  }

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

package Human::Group;

	Class::Maker::class
	{
		public =>
		{
			string => [qw( name desc )],
		},
	};

package Human::Role;

	Class::Maker::class
	{
		public =>
		{
			string => [qw( name desc )],
		},
	};

package Vehicle;

	Class::Maker::class
	{
		public =>
		{
			int => [qw( wheels )],

			string => [qw( model )],
		},
	};

package Lifeform;

	Class::Maker::class
	{
		public =>
		{
			ref => { father => 'Lifeform', mother => 'Lifeform' },
		},
	};

package Human;

	Class::Maker::class
	{
		isa => [qw( Lifeform )],
		
		public =>
		{
			int => [qw(age)],

				# look how we use multiple qw's for a single type

			string =>
			[
				qw(coutrycode postalcode firstname lastname sex eye_color),

				qw(hair_color occupation city region street fax)
			],

				# look how driverslicense has the <> syntax and therefore becomes
				# private (ie. _driverslicense)

			time => [qw(birthday dead)],

			array => [qw(nicknames friends)],

			hash => [qw(contacts telefon)],

			whatsit => { tricky => 'An::Object' },
		},

		private =>
		{
			time => [qw(driverslicense)],
		},

		  default =>
		    {
		     firstname => 'john',
		     lastname  => 'doe', 
		     sex => 'm', 

		     birthday => 'none',
		    },

		configure =>
		{
			# Future: also allow: ctor => $coderef

			ctor => 'new',

			dtor => 'delete',
		},
	};

	sub _preinit
	{
		my $this = shift;

	}

	sub _postinit
	{
		my $this = shift;

			#::printfln "Human born as %s %s today !!\n", $this->firstname, $this->lastname;
	}

package User;

	Class::Maker::class
	{
		version => '0.01',

		isa => [qw( Human )],

		public =>
		{
			int => [qw( logins )],

			real => [qw( konto )],

			string => [qw( email lastlog registered )],

			ref => { group => 'User::Group' },

			array => { friends => 'User', cars => 'Vehicle' },
		},

		  default => 
		    {
			lastlog => 'NULL',

		        registered => 'NULL',
		    },
	};

	sub _preinit
	{
		my $this = shift;
	}

package Customer;

	Class::Maker::class
	{
		version => '0.01',

		isa => [qw( User )],

		public =>
		{
			getset => [qw( firstname income payment position )],
		},

		configure =>
		{
			ctor => 'new', dtor => 'delete',
		},
	};

	sub _preinit
	{
		my $this = shift;
	}

	sub _postinit
	{
		my $this = shift;
	}

package  Employee;

	Class::Maker::class
	{
		version => '0.01',

		isa => [qw( Human )],

		#has => { Person => [qw(father mother sister brother)],

		public =>
		{
			getset => [qw( firstname income payment position )],
		},

		private =>
		{
			int => [qw( dummy1 dummy2 )],
		},

		  default => 
		    {
		     'firstname' => 'em_first',
		    },

		configure =>
		{
			ctor => 'new',

			dtor => 'delete',

			private => { prefix => '__' },
		},
	};

	sub _preinit
	{
		my $this = shift;

			#whereami();
	}

	sub _postinit
	{
		my $this = shift;

			#whereami();
	}

	sub phantom : method
	{
		my $this = shift;
	}


package main;

	ln "# We have something to dump\n";

	$Class::Maker::Reflection::DEEP = 1;
	
	#ln dump Class::Maker::Reflection::reflect( $_ ) foreach qw(Customer Employee);


#$Class::Maker::Basic::Handler::Attributes::DEBUG = 1;


ln "Employee without constructor args ";

#$Class::Maker::DEBUG = 1;
ln dump my $ezero = Employee->new();
#$Class::Maker::DEBUG = 0;


	ln dump Human->new( 'firstname' => 'employee_elma', lastname => 'jetta' );



	ln dump my $e = Employee->new( 'firstname' => 'employee_elma' );


ln "Employee isa ", dump Class::Maker::Reflection::reflect( ref $e );
	



ln 'after object constructor';

indn;
        ln "Employee::firstname ", dump $e->Employee::firstname;
        ln "Human::firstname ", dump $e->Human::firstname;

indb;

ln 'Human::firstname = "robot"';
$e->Human::firstname = "robot";

indn;
        ln "Employee::firstname ", dump $e->Employee::firstname;
        ln "Human::firstname ", dump $e->Human::firstname;

indb;


ln 'Employee::firstname = "rita"';
$e->Employee::firstname = "rita";

indn;
        ln "Employee::firstname ", dump $e->Employee::firstname;
        ln "Human::firstname ", dump $e->Human::firstname;
indb;

ln 'final test of Employee->firstname';

indn;
        ln '$e->firstname ', dump( $e->firstname );
indb;

ln 'dump $e';

indn;
        ln dump( $e );
indb;

ok( $e->{'Employee::firstname'} eq 'rita' );

ok( $e->{'Human::firstname'} eq 'robot' );
