our $VERSION = '0.002';

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

package Human;

	Class::Maker::class
	{
		version => $VERSION,

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

			time => [qw(birth dead)],

			array => [qw(nicknames friends)],

			hash => [qw(contacts telefon)],

			whatsit => { tricky => 'An::Object' },
		},

		private =>
		{
			time => [qw(driverslicense)],
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

			@$this{ qw(firstname lastname sex) } = qw( john doe male );

			@$this{ qw(birthday) } = qw(NULL);
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
	};

	sub _preinit
	{
		my $this = shift;

				@$this{qw( lastlog registered )} = qw(NULL NULL);
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

		configure =>
		{
			ctor => 'new',

			dtor => 'delete',

			explicit => 1,

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

1;
