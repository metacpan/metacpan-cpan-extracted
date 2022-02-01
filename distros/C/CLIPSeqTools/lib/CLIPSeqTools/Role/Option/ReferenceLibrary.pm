=head1 NAME

CLIPSeqTools::Role::Option::ReferenceLibrary - Role to enable reading
reference libraries with reads from the command line

=head1 SYNOPSIS

Role to enable reading reference libraries with reads from the command line

  Defines options.
      -r_driver <Str>          driver for database connection  for reference
                               library(eg. mysql, SQLite).
      -r_database <Str>        database name or path for reference library
                               (eg. SQLite).
      -r_table <Str>           database table for reference library.
      -r_host <Str>            hostname for database connection for reference
                               library.
      -r_user <Str>            username for database connection for reference
                               library.
      -r_password <Str>        password for database connection for reference
                               library.
      -r_records_class <Str>   type of records stored in database for
                               reference library (Default: GenOO::Data::DB::
                               DBIC::Species::Schema::SampleResultBase::v3).
      -r_filter <Filter>       filter library. Option can be given multiple
                               times.
                               Syntax: column_name="pattern"
                                 e.g. -filter deletion="def"
                                      -filter rmsk="undef"
                                 to keep reads with deletions and not repeat
                                 masked.
                                 e.g. -filter query_length=">31"
                                      -filter query_length="<=50"
                                 to keep reads longer than 31 and shorter or
                                 equal to 50.
                               Supports: >, >=, <, <=, =, !=, def, undef.

  Provides attributes.
      r_reads_collection      reads collection that is read from the specified
                              source.

=cut


package CLIPSeqTools::Role::Option::ReferenceLibrary;
$CLIPSeqTools::Role::Option::ReferenceLibrary::VERSION = '1.0.0';

#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use MooseX::App::Role;
use MooseX::Getopt;


#######################################################################
########################   Load GenOO modules   #######################
#######################################################################
use GenOO::RegionCollection::Factory;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'r_driver' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'SQLite',
	documentation => 'driver for database connection (eg. mysql, SQLite).',
	cmd_tags        => ['Reference library'],
);

option 'r_database' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'database name or path.',
	cmd_tags      => ['Reference library'],
);

option 'r_table' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'sample',
	documentation => 'database table.',
	cmd_tags      => ['Reference library'],
);

option 'r_host' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => 'hostname for database connection.',
	cmd_tags        => ['Reference library'],
);

option 'r_user' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => 'username for database connection.',
	cmd_tags      => ['Reference library'],
);

option 'r_password' => (
	is            => 'rw',
	isa           => 'Str',
	documentation => 'password for database connection.',
	cmd_tags      => ['Reference library'],
);

option 'r_filter' => (
	is            => 'rw',
	isa           => 'ArrayRef',
	default       => sub { [] },
	documentation => 'filter reference library. Option can be given '.
						'multiple times. Syntax: column_name="pattern" '.
						'e.g. --r_filter deletion="def" '.
						'--r_filter rmsk="undef" '.
						'--r_filter query_length=">31" to keep reads with '.
						'deletions AND not repeats AND longer than 31. '.
						'Supports: >, >=, <, <=, =, !=, def, undef.',
	cmd_tags      => ['Reference library'],
);


#######################################################################
######################   Interface Attributes   #######################
#######################################################################
has 'r_reads_collection' => (
	traits    => [ 'NoGetopt' ],
	is        => 'rw',
	builder   => '_build_reference_collection',
	lazy      => 1,
);

has 'r_records_class' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'GenOO::Data::DB::DBIC::Species::Schema'.
						'::SampleResultBase::v3',
	documentation => 'type of records stored in database.',
	cmd_tags      => ['Reference library'],
);


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {}


#######################################################################
#########################   Private Methods   #########################
#######################################################################
sub _build_reference_collection {
	my ($self) = @_;

	my $collection = $self->_build_reference_collection_from_database;
	_apply_simple_filters_on_reference_collection($self->filter, $collection);
	return $collection;
}

sub _build_reference_collection_from_database {
	my ($self) = @_;

	return GenOO::RegionCollection::Factory->create('DBIC', {
		driver        => $self->r_driver,
		host          => $self->r_host,
		database      => $self->r_database,
		user          => $self->r_user,
		password      => $self->r_password,
		table         => $self->r_table,
		records_class => $self->r_records_class,
	})->read_collection;
}


#######################################################################
########################   Private Functions   ########################
#######################################################################
sub _apply_simple_filters_on_reference_collection {
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
