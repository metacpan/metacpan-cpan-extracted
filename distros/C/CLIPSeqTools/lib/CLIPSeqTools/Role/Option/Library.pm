=head1 NAME

CLIPSeqTools::Role::Option::Library - Role to enable reading a library with
reads from the command line

=head1 SYNOPSIS

Role to enable reading a library with reads from the command line

  Defines options.
      -driver <Str>          driver for database connection (eg. mysql, SQLite).
      -database <Str>        database name or path to database file for file
                             based databases (eg. SQLite).
      -table <Str>           database table.
      -host <Str>            hostname for database connection.
      -user <Str>            username for database connection.
      -password <Str>        password for database connection.
      -records_class <Str>   type of records stored in database (Default:
                             GenOO::Data::DB::DBIC::Species::Schema::
                             SampleResultBase::v3).
      -filter <Filter>       filter library. Option can be given multiple times.
                             Syntax: column_name="pattern"
                             e.g. -filter deletion="def" -filter rmsk="undef"
                             to keep reads with deletions and not repeat
                             masked.  e.g.  -filter query_length=">31" -filter
                             query_length="<=50" to keep reads longer than 31
                             and shorter or   equal to 50.  Supported
                             operators: >, >=, <, <=, =, !=, def, undef.

  Provides attributes.
      reads_collection      reads collection that is read from the specified
                            source.

=cut


package CLIPSeqTools::Role::Option::Library;
$CLIPSeqTools::Role::Option::Library::VERSION = '1.0.0';

#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use MooseX::App::Role;


#######################################################################
########################   Load GenOO modules   #######################
#######################################################################
use GenOO::RegionCollection::Factory;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'driver' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'SQLite',
	documentation => 'driver for database connection (eg. mysql, SQLite).',
);

option 'database' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'database name or path.',
);

option 'table' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'sample',
	documentation => 'database table.',
);

option 'host' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => 'hostname for database connection.',
);

option 'user' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => 'username for database connection.',
);

option 'password' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => 'password for database connection.',
);

option 'filter' => (
	is            => 'rw',
	isa           => 'ArrayRef',
	default       => sub { [] },
	documentation => 'filter library. Option can be given multiple times. '.
                     'Syntax: column_name="pattern" '.
                     'e.g. --filter deletion="def" --filter rmsk="undef" '.
                     '--filter query_length=">31" to keep reads with '.
                     'deletions AND not repeats AND longer than 31. '.
                     'Supported operators: >, >=, <, <=, =, !=, def, undef.',
);


#######################################################################
######################   Interface Attributes   #######################
#######################################################################
has 'reads_collection' => (
	is        => 'rw',
	builder   => '_build_collection',
	lazy      => 1,
);

has 'records_class' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'GenOO::Data::DB::DBIC::Species::Schema::' .
						'SampleResultBase::v3',
	documentation => 'type of records stored in database.',
);


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {}


#######################################################################
#########################   Private Methods   #########################
#######################################################################
sub _build_collection {
	my ($self) = @_;

	my $collection = $self->_build_collection_from_database;
	_apply_simple_filters_on_collection($self->filter, $collection);
	return $collection;
}

sub _build_collection_from_database {
	my ($self) = @_;

	return GenOO::RegionCollection::Factory->create('DBIC', {
		driver        => $self->driver,
		host          => $self->host,
		database      => $self->database,
		user          => $self->user,
		password      => $self->password,
		table         => $self->table,
		records_class => $self->records_class,
	})->read_collection;
}


#######################################################################
########################   Private Functions   ########################
#######################################################################
sub _apply_simple_filters_on_collection {
	my ($filters, $collection) = @_;

	my @elements = @{$filters};
	foreach my $element (@elements) {
		$element =~ /^(.+?)=(.+?)$/;
		my $col_name = $1;
		my $filter   = $2;
		$collection->simple_filter($col_name, $filter);
	}
}


1;
