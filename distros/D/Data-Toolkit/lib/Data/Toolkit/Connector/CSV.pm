#!/usr/bin/perl -w
#
# Data::Toolkit::Connector::CSV
#
# Andrew Findlay
# Nov 2006
# andrew.findlay@skills-1st.co.uk
#
# $Id: CSV.pm 388 2013-08-30 15:19:23Z remotesvn $

package Data::Toolkit::Connector::CSV;

use strict;
use Carp;
use Clone qw(clone);
use Data::Dumper;

use Data::Toolkit::Entry;
use Data::Toolkit::Connector;
our @ISA = ("Data::Toolkit::Connector");

=head1 NAME

Data::Toolkit::Connector::CSV

=head1 DESCRIPTION

Connector for reading CSV files.

=head1 SYNOPSIS

   $conn2 = Data::Toolkit::Connector::CSV->new();
   open SOURCE, "<mydata.csv";
   my $csvParser = Text::CSV_XS->new();
   $conn2->parser( $csvParser );
   $conn2->datasource( sub { return <SOURCE> } );
   $conn2->columns( ['one','two','three'] );
   while ($entry = $conn2->next()) {
      print $entry->dump(), "\n";
   }



=head1 DEPENDENCIES

   Carp
   Clone
   Text::CSV_XS    for testing

=cut

########################################################################
# Package globals
########################################################################

use vars qw($VERSION);
$VERSION = '1.0';

# Set this non-zero for debug logging
#
my $debug = 0;

########################################################################
# Constructors and destructors
########################################################################

=head1 Constructor

=head2 new

   my $csvConn = Data::Toolkit::Connector::CSV->new();

Creates an object of type Data::Toolkit::Connector::CSV

=cut

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless ($self, $class);

	$self->{linecount} = 0;

	carp "Data::Toolkit::Connector::CSV->new $self" if $debug;
	return $self;
}

sub DESTROY {
	my $self = shift;
	carp "Data::Toolkit::Connector::CSV Destroying $self" if $debug;
}

########################################################################
# Methods
########################################################################

=head1 Methods

=cut

########################################

=head2 parser

Define the CSV parser for the connector to use.
This should be an object of type Text::CSV_XS or similar.

   my $res = $csvConn->parser( Text::CSV_XS->new() );

Returns the object that it is passed.

=cut

sub parser {
	my $self = shift;
	my $parser = shift;

	croak "Data::Toolkit::Connector::CSV->parser expects a parameter" if !$parser;
	carp "Data::Toolkit::Connector::CSV->parser $self" if $debug;

	return $self->{parser} = $parser;
}

########################################

=head2 datasource

Specify a data source.
This should be a reference to a procedure that returns one line of text per call.

If the parameter is undef, data will be read using the magic "<>" token

   my $res = $csvConn->datasource( sub { return <SOURCE>; } );

Returns the object that it is passed.

=cut

sub datasource {
	my $self = shift;
	my $source = shift;

	carp "Data::Toolkit::Connector::CSV->datasource $self" if $debug;

	# Reset the linecount as we have a new datasource
	$self->{linecount} = 0;
	$self->{currentline} = undef;

	return $self->{datasource} = $source;
}

########################################

=head2 columns

Specify the names of the columns in the CSV file

   my $arrayRef = $csvConn->columns( ['firstname','surname','mail','phone'] );
   my $arrayRef = $csvConn->columns();

Returns the list of columns as an array or array reference

=cut

sub columns {
	my $self = shift;
	my $cols = shift;

	if ($cols) {
		croak "Data::Toolkit::Connector::CSV->columns expects an array reference" if ((ref $cols) ne 'ARRAY');
		carp "Data::Toolkit::Connector::CSV->columns $self $cols" if $debug;
		$self->{config}->{cols} = clone( $cols );
	}
	else {
		carp "Data::Toolkit::Connector::CSV->columns $self" if $debug;
	}

	my @colReturn = $self->{config}->{cols};

	return wantarray ? @colReturn : \@colReturn;
}

########################################

=head2 colsFromFile

Read the column names from the first line of the CSV file

   my $entry = $csvConn->colsFromFile();

Returns the list of columns on success, or undef on failure.

It is an error to call this method without first calling the
datasource and parser methods. Doing so will cause an exception
to be thrown.

=cut

sub colsFromFile {
	my $self = shift;

	carp "Data::Toolkit::Connector::CSV->colsFromFile $self" if $debug;

	croak "colsFromFile called but no parser yet defined" if !$self->{parser};

	my $line;
	# Use the datasource procedure if we have one
	# Otherwise, read from the 'magic open' file
	#
	if (defined($self->{datasource})) {
		$line = $self->{datasource}();
	}
	else {
		$line = <>;
	}
	return undef if !defined($line);
	chomp $line;

	# Count lines and stash the current one for reference
	$self->{linecount}++;
	$self->{currentline} = $line;

	# Parse the line to find the field names
	my $status = $self->{parser}->parse( $line );
	return undef if not $status;

	my @fields = $self->{parser}->fields();
	$self->{config}->{cols} = \@fields;

	carp "Data::Toolkit::Connector::CSV->colsFromFile returning $line" if $debug;

	return wantarray ? @fields : \@fields;
}


########################################

=head2 next

Read the next entry from the CSV file

   my $entry = $csvConn->next();

The result is a Data::Toolkit::Entry object if there is data left in the file,
otherwise it is undef.

=cut

sub next {
	my $self = shift;

	carp "Data::Toolkit::Connector::CSV->next $self" if $debug;

	# print "####" . Dumper($self) . "\n";

	my $line;
	# Use the datasource procedure if we have one
	# Otherwise, read from the 'magic open' file
	#
	if (defined($self->{datasource})) {
		$line = $self->{datasource}();
	}
	else {
		$line = <>;
	}
	return undef if !defined($line);
	chomp $line;

	# Count lines and stash the current one for reference
	$self->{linecount}++;
	$self->{currentline} = $line;

	my $status = $self->{parser}->parse( $line );
	return undef if not $status;

	my @fields = $self->{parser}->fields();

	my $entry = Data::Toolkit::Entry->new();

	# Now step through the list of columns and assign data to attributes in the entry
	my $colname;
	my $col = 0;
	my $names = $self->{config}->{cols};

	foreach $colname (@$names) {
		$entry->set( $colname, [ $fields[$col] ] );
		$col++;
	}

	carp "Data::Toolkit::Connector::CSV->next returning data $line" if $debug;

	return $entry;
}


########################################

=head2 linecount

Return the number of the line that we are currently processing

   $count = $csvConn->linecount();

=cut

sub linecount {
	my $self = shift;

	my $count = $self->{linecount};
	carp "Data::Toolkit::Connector::CSV->linecount $self returns $count" if $debug;

	return $count;
}

########################################

=head2 currentline

Return the line that we are currently processing

   $count = $csvConn->currentline();

=cut

sub currentline {
	my $self = shift;

	my $line = $self->{currentline};
	carp "Data::Toolkit::Connector::CSV->currentline $self returns '$line'" if $debug;

	return $line;
}

########################################################################
# Debugging methods
########################################################################

=head1 Debugging methods

=head2 debug

Set and/or get the debug level for Data::Toolkit::Connector

   my $currentDebugLevel = Data::Toolkit::Connector::CSV->debug();
   my $newDebugLevel = Data::Toolkit::Connector::CSV->debug(1);

Any non-zero debug level causes the module to print copious debugging information.

Note that this is a package method, not an object method. It should always be
called exactly as shown above.

All debug information is reported using "carp" from the Carp module, so if
you want a full stack backtrace included you can run your program like this:

   perl -MCarp=verbose myProg

=cut

# Class method to set and/or get debug level
#
sub debug {
	my $class = shift;
	if (ref $class)  { croak "Class method 'debug' called as object method" }
	# print "DEBUG: ", (join '/', @_), "\n";
	$debug = shift if (@_ == 1);
	return $debug
}


########################################################################
########################################################################

=head1 Author

Andrew Findlay

Skills 1st Ltd

andrew.findlay@skills-1st.co.uk

http://www.skills-1st.co.uk/

=cut

########################################################################
########################################################################
1;
