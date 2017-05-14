BEGIN
{
	$| = 1; print "1..1\n";
}

my $loaded;

use strict;

use Carp;

use IO::Extended ':all';

use Data::Dumper;

use Class::Maker;

use Class::Maker::Extension::Schema::Tangram qw(schema);

	use DBI;

	use Tangram;

		# custom tangram extented types

	use Tangram::FlatHash;	# for hashes

	use Tangram::FlatArray;	# for array

	use Tangram::RawDate;	# strings to SQL date/time types

	use Tangram::RawTime;

	use Tangram::RawDateTime;

Class::Maker::class 'Human',
{
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

		time => [qw(birth driverslicense dead)],

		array => [qw(nicknames friends)],

		hash => [qw(contacts telefon)],
	},

	configure =>
	{
		# Future: also allow: ctor => $coderef

		ctor => 'new',

		dtor => 'delete',
	},
};

	sub Human::_preinit
	{
		my $this = shift;

			@$this{ qw(firstname lastname sex) } = qw( john doe male );

			@$this{ qw(birthday) } = qw(NULL);
	}

	sub Human::_postinit
	{
		my $this = shift;

			#::printfln "Human born as %s %s today !!\n", $this->firstname, $this->lastname;
	}

Class::Maker::class 'Vehicle',
{
	public =>
	{
		int => [qw( wheels )],

		string => [qw( model )],
	},
};

Class::Maker::class 'User',
{
	version => '0.01',

	isa => [qw( Human )],

	public =>
	{
		int => [qw( logins )],

		real => [qw( konto )],

		string => [qw( email lastlog registered )],

		ref => { group => 'Human::Group' },

		array => { friends => 'User', cars => 'Vehicle' },
	},

	default =>
	{
		lastlog => 'NULL',

		registered => 'NULL',
	},
};

	sub User::info : method
	{
		my $this = shift;

		printf "group: '%s' ", $this->group->name();

			foreach ( qw(age konto) )
			{
				print "$_: '$this->{$_}' ";
			}

		print "\n";

	return;
	}

Class::Maker::class 'Human::Group',
{
	public =>
	{
		string => [qw( name desc )],
	},
};

	sub Human::Group::info : method
	{
		my $this = shift;

			foreach ( qw(name desc) )
			{
				print "$_: '$this->{$_}' ";
			}

		print "\n";

	return;
	}

	$| = 0;

	print Dumper [ User->new() ];

	$Class::Maker::DEBUG = 1;

	my $class_schema = schema( 'User' );

	print Dumper [ $class_schema ];

printf "ok %d\n", ++$loaded;

	exit;

	my $schema = Tangram::Relational->schema( { classes => $class_schema,normalize => sub { $_[0] =~ s/::/_/; $_[0] } } );

	my $dbh = DBI->connect( ) or die;

	{
		my $aref_result = $dbh->selectcol_arrayref( q{SHOW TABLES} ) or die $DBI::errstr;

		my %tables;

		@tables{ @$aref_result } = 1;

		Tangram::Relational->deploy( $schema, $dbh ) unless exists $tables{'tangram'};
	}

	# To delete all tangram tables of this schema
	#
	# Tangram::Relational->retreat( $schema, $dbh );

	my $storage = Tangram::Relational->connect( $schema, @ENV{ qw(DBI_DSN DBI_USER DBI_PASS) }, { dbh => $dbh } ) or die;

	my $tbl = $storage->remote( 'Human::Group' );

	my ($group) = $storage->select( $tbl, $tbl->{name} eq 'dbadmin' );

	unless( $group )
	{
		$group = new Human::Group( -name => 'dbadmin', -desc => 'database administrators' );

		print Dumper $group;

		$storage->insert( $group );
	}

	$tbl = $storage->remote( 'Human' );

	my @users = map { new User( -age => (0 .. 100)[rand 99], -konto => int rand 99, -group => $group ) } (1..3);

	print $users[0]->to_xml;

	my @id = $storage->insert(

			@users,

			new Human( -firstname => 'test_person' ),

		) or die q{insert failed..};

	println 'Scanning for teenagers (age<18)...';

	map { $_->info() } $storage->select( $tbl, $tbl->{age} < 18 );

	println 'Scanning finished.';

		# list all instances

	my %class_hash = @$class_schema;

	foreach my $class ( keys %class_hash )
	{
		my $cursor = $storage->cursor( $class );

		my $inst_cnt = 0;

		while(my $obj = $cursor->current())
		{
			#$obj->info() if $obj->can('info');

			$inst_cnt++;

			$cursor->next();
		}

		println qq{'$inst_cnt' instance(s) of class '$class' detected.};

		$cursor->close();
	}

	eval
	{
		1;
	};

	if($@)
	{
		croak $@;

		print 'not ';
	}

printf "ok %d\n", ++$loaded;


=head1 Method B<intelligent_deploy>

Test whether tangram is installed, otherwise deploy the schema into the db.

=cut
