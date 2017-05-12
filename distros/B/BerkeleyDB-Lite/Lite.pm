package BerkeleyDB::Lite ;

#     Copyright (c) 1997-2001 Jim Schueler. All rights reserved.
#     This program is free software; you can redistribute it and/or
#     modify it under the same terms as Perl itself.
#

# The documentation for this module is at the bottom of this file,
# after the line __END__.

use BerkeleyDB ;
use Storable qw( nfreeze thaw ) ;
use Carp ;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '1.1';
## See Changes file

our @defaults = ( 
		rootdir => "/usr/local/apache/cgi-bin/db" 
		) ;

our ( %env, %dbreg ) ;

our @ISA = qw( Exporter );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use BerkeleyDB::Lite::Hash ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( duplicatekeys incrementkeys uniquepairs uniquekeys );

## Problems have occured during global destruction if Env objects are
## closed before database objects.  %dbreg closes all open databases 
## first.
END {
	closeall() ;
	}

## Run closeall if forking child processes.  All references must be destroyed
## first.
sub closeall {
	map { eval { $_->db_close } } values %dbreg ;
	%env = () ;
	}

sub new {
	my $invocator = shift ;
	my $class = ref $invocator || $invocator ;

	my $self = $class->scalars( @_ ) ;
	my $ref = tied %$self ;

	return undef unless $ref ;

	$ref->filter_store_value (
			sub {
				$_ = nfreeze( ref $_? $_: \$_ ) ;
				} ) ;

	$ref->filter_fetch_value (
			sub {
				$_ = thaw $_ ;
				} ) ;

	return bless $self, $class ;
	}

sub uniquekeys {
	return 1 ;
	}

sub duplicatekeys {
	return property => DB_DUP ;
	}

sub uniquepairs {
	return 	property => DB_DUP | DB_DUPSORT ;
	}

sub incrementkeys {
	return compare => sub { ( $_[0] || 0 ) <=> ( $_[1] || 0 ) } ;
	}

sub envsetup {
	my %config = ( @defaults, @_ ) ;
	croak "'home' not defined" unless $config{home} ;
	croak "'filename' not defined" unless $config{filename} ;

	### Environment ###
	my %args_env = () ;
	$args_env{'-Cachesize'} = $config{cachesize}
			if exists $config{cachesize} ;
	if ( exists $config{server} ) {
		$args_env{'-Server'} = $config{server} ;
		$args_env{'-Home'} = $config{home} ;
		}
	else {
		$args_env{'-Home'} = "$config{rootdir}/$config{home}" ;
		}

	my $flags = DB_CREATE | DB_INIT_MPOOL | DB_INIT_CDB ;
	$flags ||= DB_RECOVER if $config{recover} ;

	$env{ $config{home} } ||= new BerkeleyDB::Env
			%args_env,
			-Flags => $flags,
			or warn "$!" ;

	### Database ###
	my %args_db = () ;
	$args_db{filename} = "$config{rootdir}/$config{home}/$config{filename}"
			unless $config{server} ;
	$args_db{'-Env'} = $env{ $config{home} } ;
	$args_db{'-Filename'} = $config{filename} ;
	$args_db{'-Property'} = $config{property} if exists $config{property} ;
	$args_db{'-Compare'} = $config{compare} if exists $config{compare} ;

	return %args_db ;
	}

## intended for duplicatekeys
sub recordset {
	my $ref = shift ;
	my $self = tied %$ref ;
	my $key = shift ;
	my $value = "" ;

	my @values = () ;

	# database locked
	my $cursor = $self->db_cursor ;

	if ( $cursor->c_get( $key, $value, DB_SET ) ) {
		$cursor = undef ;
		return @values ;
		}

	push @values, $value ;
	while ( ! $cursor->c_get( $key, $value, DB_NEXT_DUP ) ) {
		push @values, $value ;
		}

	$cursor = undef ;
	return @values ;
	}

## experimental to improve durability
sub sync {
	my $ref = shift ;
	my $self = tied %$ref ;
	$self->db_sync ;
	}

sub syncall {
	map { $_->db_sync } values %dbreg ;
	}

## intended for duplicatekeys
sub delete {
	my $ref = shift ;
	my $self = tied %$ref ;
	my $key = shift ;
	my $value = shift ;
	my $orig = $value ;

	my $cursor = $self->db_cursor( DB_WRITECURSOR ) ;
	my $status = $cursor->c_get( $key, $value, DB_GET_BOTH ) ;

	## Warning: Ensure consistency between numbers with strings.
	## See Storable documentation.
	$cursor->c_del unless $status ;
	$cursor = undef ;

	return $status ;
	}

sub DESTROY {
	my $ref = shift ;
	my $self = tied %$ref ;
	return unless $self ;

	delete $dbreg{ $self->[0] } ;

	## Sleepycat suggests that as an RPC client, db_close is a noop.
	## In that case, db_sync ought to be called instead.
	## How to check whether db's env uses RPC?
	eval { $self->db_sync } ;

	eval { $self->db_close } ;
	}


package BerkeleyDB::Lite::Hash ;

use BerkeleyDB ;
use Carp ;

our @ISA = qw( BerkeleyDB::Lite ) ;

sub scalars {
	my $invocator = shift ;
	my $class = ref $invocator || $invocator ;
	my( $self, %self ) ;

	my %env = BerkeleyDB::Lite::envsetup( @_ ) ;

	my %alt = @_ ;
	my $filename = $env{filename} ;
	delete $env{filename} ;

	### Table ###
	$self = tie %self, $alt{subclass} || 'BerkeleyDB::Hash',
			%env,
			-Flags => DB_CREATE, 
			or warn "($$) $filename: $!"
			if $env{'-Env'} ;

	## Failsafe- open R/O without locking
	if ( $filename && ! $self ) {
		delete $env{ '-Filename' } ;
		delete $env{ '-Env' } ;
	
		$self = tie %self, 'BerkeleyDB::Hash',
				-Filename => $filename,
				-Flags => DB_RDONLY, 
				%env,
				or warn "$filename: $! (readonly)" ;
		}

	$dbreg{ $self->[0] } = $self if ref $self ;
	return bless \%self, $class ;
	}


package BerkeleyDB::Lite::Btree ;

use BerkeleyDB ;
use Carp ;

our @ISA = qw( BerkeleyDB::Lite ) ;

sub lexical {
	my $invocator = shift ;
	my $class = ref $invocator || $invocator ;

	return BerkeleyDB::Lite::Btree::Lexical->new( @_ ) ;
	}

sub scalars {
	my $invocator = shift ;
	my $class = ref $invocator || $invocator ;
	my( $self, %self ) ;

	my %env = BerkeleyDB::Lite::envsetup( @_ ) ;

	my %alt = @_ ;
	my $filename = $env{filename} ;
	delete $env{filename} ;

	### Table ###
	$self = tie %self, $alt{subclass} || 'BerkeleyDB::Btree',
			%env,
			-Flags => DB_CREATE, 
			or warn "$filename $!"
			if $env{'-Env'} ;

	## Failsafe- open R/O without locking
	if ( $filename && ! $self ) {
		delete $env{ '-Filename' } ;
		delete $env{ '-Env' } ;
	
		$self = tie %self, 'BerkeleyDB::Btree',
				-Filename => $filename,
				-Flags => DB_RDONLY, 
				%env,
				or warn "$filename $!" ;
		}

	$dbreg{ $self->[0] } = $self if ref $self ;
	return bless \%self, $class ;
	}

sub dosearch {
	my $ref = shift ;
	my $self = tied %$ref ;
	my $partkey = shift ;
	my $isunique = shift ;

	my %unique = () ;
	my @keys = () ;
	my @values = () ;
	my @each = () ;

	return [] unless $partkey ;
	my $length = length $partkey ;

	# database locked
	my $cursor = $self->db_cursor ;

	my $value = 0 ;
	my $key = $partkey ;
	my $status = $cursor->c_get( $key, $value, DB_SET_RANGE ) ;
	
	while ( $key ) {
		last if $status || substr( $key, 0, $length ) ne $partkey ;

		if ( $isunique ) {
			$unique{ $key }++ ;
			}
		else {
			push @each, [ $key, $value ] ;
			}

		$status = $cursor->c_get( $key, $value, DB_NEXT ) ;
		}

	
	$cursor = undef ;
	@each = map { [ $_, $unique{$_} ] } keys %unique if $isunique ;
	return \@each ;
	}

sub matchingkeys {
	return map { $_->[0] } @{ dosearch( @_ ) } ;
	}

sub matchingvalues {
	return map { $_->[1] } @{ dosearch( @_ ) } ;
	}

sub searchset {
	return map { @$_ } @{ dosearch( @_ ) } ;
	}

## intended for Btree's with incremented keys
sub nextrecord {
	my $ref = shift ;
	my $self = tied %$ref ;

	my $key = 0 ;
	my $value = 0 ;
	my $cursor = $self->db_cursor() ;
	$cursor->c_get( $key, $value, DB_LAST ) ;

	$ref->{ $key +1 } = {} ;
	$cursor = undef ;
	return $key +1 ;
	}


package BerkeleyDB::Lite::Btree::Lexical ;
	
our @ISA = qw( BerkeleyDB::Lite::Btree ) ;

sub scalars {
	my $invocator = shift ;
	my $class = ref $invocator || $invocator ;

	my $self = BerkeleyDB::Lite::Btree->scalars( @_ ) ;
	my $ref = tied %$self ;

	return undef unless $ref ;

	$ref->filter_store_key (
			sub {
				$_ = sprintf "%010d", $_ ;
				} ) ;

	$ref->filter_fetch_key (
			sub {
				$_ = sprintf "%d", $_ ;
				} ) ;

	return bless $self, $class ;
	}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

BerkeleyDB::Lite - Simplified Interface to BerkeleyDB

=head1 SYNOPSIS

  use BerkeleyDB::Lite;


=head2 ## Example 1

  ## Create a Hashed database
  my $db = new BerkeleyDB::Lite::Hash
		home => 'zoo',
		filename => 'residents' ;

  $db->{Samson} = new Primate ;
  $db->{Cornelius} = new Primate ;
  $db->{Kaa} = new Reptile ;


=head2 ## Example 2

  ## Create a Btree database allowing duplicates and scalar values
  my $types = scalars BerkeleyDB::Lite::Btree
		home => 'zoo',
		filename => 'types',
		&duplicatekeys ;

  $types->{primate} = 'Samson' ;
  $types->{primate} = 'Cornelius' ;
  $types->{reptile} = 'Kaa' ;

  printf "%s\n", join ' ', $types->recordset{primate} ;
  ## prints: Samson Cornelius

  $types->delete( primate => 'Samson' ) ;
  printf "%s\n", join ' ', $types->recordset{primate} ;
  ## prints: Cornelius


=head2 ## Example 3

  ## Create a database of visitors
  ## Use a table with arbitrary keys
  ## Track visitors by date/timestamp

  $tickets = new BerkeleyDB::Lite::Btree
		home => 'zoo',
		filename => 'tickets',
		&incrementkeys ;

  ## Lexical Alternative
  # $tickets = lexical BerkeleyDB::Lite::Btree
  #		home => 'zoo',
  #		filename => 'tickets' ;

  $bytime = scalars BerkeleyDB::Lite::Btree
		home => 'zoo',
		filename => 'ticketsbytime',
		&duplicatekeys ;

  ## Process a new visitor in real time
  sub newvisitor {
	my $serial = $tickets->nextrecord() ;
        my $date = getdate() ;	## not part of BerkeleyDB::Lite
	my $time = gettime() ;	## not part of BerkeleyDB::Lite

	$tickets->{$serial} = { @_ } ;
	$bytime->{ "$date $time" } = $serial ;
	return $serial ;
	}

  ## Get a list of visitors on a certain date
  sub showvisitorsbydate {
	my $date = shift ;
	return $bytime->matchingvalues( $date ) ;
	}

=head1 DESCRIPTION

BerkeleyDB::Lite is an interface to Paul Marquess's BerkeleyDB
that provides simplified constructors, tied access to data, and 
methods for returning multiple record sets.

=head2 Example 1

BerkeleyDB::Lite maintains BerkeleyDB environment references
in a package variable hash keyed on the B<home> argument.  The 
basic BerkeleyDB::Lite constructor arguments define the 
BerkeleyDB environment and database.  When the constructor 
is called, a previously opened environment is used if 
available.  Otherwise, a new environment is created and is 
available to future constructor requests.

This version of BerkeleyDB::Lite creates all environment objects 
as concurrent data stores.  Transactional data storage is not 
currently integrated.

By default, BerkeleyDB::Lite is designed to marshall objects into a 
database using the B<Storable> module.

Example 1 shows a simple application that illustrates both of 
these features.  The constructor is called with the minimum 
arguments to identify the environment and the database.

These few lines of code are sufficient to add persistent object 
support to an application.


=head2 Example 2

One of Berkeley's most appealing features is support for 
duplicate keys.  This feature enables a programmer to use 
persistent arrays, where elements can be accessed, added, 
and deleted without marshalling.
 
Example 2 uses the B<scalars> constructor which disables the 
automatic serialization of record access.  Otherwise, if the 
B<new> constructor is used, scalars will be returned as scalar 
references, regardless of how they are stored.

B<&duplicatekeys> is a subroutine that returns a pair of 
constants as a shortcut.  The constants are defined in the 
BerkeleyDB module.

The B<recordset> method returns a stored list from the database.  
This method is available to both BerkeleyDB::Lite::Btree and
BerkeleyDB::Lite::Hash classes.

The B<delete> method is used to delete an element from the list.  
Since BerkeleyDB::Lite adheres to the B<Tie> interface, the 
B<delete function> can normally used to remove stored objects.  
The B<delete method> should be used on databases with duplicate 
keys to avoid indeterminate results.

BerkeleyDB returns the status of a delete operation.  This 
feature can be used to delete an entire list using the following 
idiom:

  while ( ! delete $types->{primate} ) {}


A BerkeleyDB database configured for duplicate keys also allows 
duplicate key/value pairs.  For most one-to-many data sets, 
key/value pairs should be unique.  This issue has not been 
completely resolved.  Presently, the workaround is to import a 
retrieved list into a hash structure:

  %unique = map { $_ => 1 } $types->recordset('primate') ;
  keys %unique ;


However, care should be taken when deleting elements.  The 
delete method for duplicate keys should almost always be 
invoked using an idiom similar to the one above:

  while ( ! $types->delete( primate => 'samson' ) ) {}


Another source of problems occurs when using the B<delete> 
method on databases containing objects.  In this case, the 
second argument may refer to an object that does not exactly 
match the stored value.  The following code illustrates this 
difficulty:

  my $cats = new BerkeleyDB::Lite::Btree(
		home => 'zoo',
		filename => 'cats',
		&duplicatekeys,
		) ;

  my $Felix = new BigCat dinner => 'antelope' ;
  $cats->{lion} = $Felix ;
  $Felix->{dinner} = 'gazelle' ;
  $cats->delete( lion => $Felix ) ;		## fails


This problem also occurs because the results of the 
marshalling operation differ depending on whether numbers 
are interpreted as integers, floats, or strings.  Thus an 
object's value may change merely as a result of its 
context.  The following example illustrates the situation:

  $weight = '300 lbs.' ;
  $weight =~ s/\D//g ;
  my $Felix = new BigCat( weight => $weight ) ;	## member as string
  $cats->{lion} = $Felix ;
  $cats->delete( lion => $Felix )		## operation fails
		if $Felix->{weight} > 200 ;	## member as integer 


=head2 Example 3

Example 3 shows a few additional features helpful to 
developers accustomed to relational databases.  These 
features take advantage of the B<Btree> database capabilities, 
and are not available to BerkeleyDB::Lite::Hash objects.

The B<nextrecord> method of BerkeleyDB::Lite::Btree returns 
a new unique key.  Each B<nextrecord> call creates a new 
blank record to avoid race conditions, and returns the new 
key.  This method creates a key by adding 1 to the last 
record.  In order to ensure that the last record contains 
the highest valued key, use the B<&incrementkeys> argument 
to the BerkeleyDB::Lite::Btree constructor.  The 
B<&incrementkeys> function is a shortcut that returns a 
CODE constant that forces numerical Btree sorting.

There is a significant disadvantage to databases created 
using the B<&incrementkeys> argument.  The resulting 
databases are incompatible with SleepyCat utilities such as 
B<db_dump> and B<db_verify>.  As an alternative, 
B<nextrecord> can be called as a method from the
BerkeleyDB::Lite::Btree::Lexical subclass.  This subclass 
functions identically, but the numerical keys are stored 
as zero padded strings.  Therefore, a restriction on 
B<Lexical> subclass databases is that keys must be 
numerically less than 10,000,000,000.

The B<lexical> constructor to the BerkeleyDB::Lite::Btree 
class is synonymous with the B<new> constructor to the 
BerkeleyDB::Lite::Btree::Lexical subclass.

BerkeleyDB::Lite also implements another nice Berkeley
feature: partial string matching.  The methods 
B<matchingkeys>, B<matchingvalues>, and B<searchset> 
all return a set of records whose keys begin with a 
common substring.

For example, if keys are defined with the following 
format: S<"2002 Jul 14 15:30">, the following data can 
be returned:

  ## All records for the year
  @annually = $bytime->matchingkeys('2002 ') ;

  ## All records for the month
  @monthly = $bytime->matchingvalues('2002 Jul ') ;

  ## All records for the day
  %daily = $bytime->searchset('2002 Jul 14 ') ;	

B<matchingkeys> returns an array of the matching records' 
keys.  B<matchingvalues> returns an array of the matching 
records' values.  Unforeseen confusion may result from the 
method name B<matchingvalues>- the returned records have 
matching keys, but the record values are returned.

B<searchset> returns the matching records as key/value pairs 
that can populate an associative array as shown.  However, 
using an associative array is pointless if the 
database contains duplicate keys.  The following code is an 
effective technique for capturing the results of this type 
of search:

    foreach ( $bytime->matchingkeys( '2002 Jul 14', &uniquekeys ) ) {
	$daily{ $_ } = [ $bytime->recordset( $_ ) ] ;
	}

B<&uniquekeys> returns a constant that is used primarily as 
an argument to the B<matchingkeys> method to filter duplicate 
results from the database.  When this argument is passed to 
the B<&searchset> method, the values in the key/value pairs 
indicate a record count.  B<&uniquekeys> cannot be used with 
the B<matchingvalues> method.


=head2 EXPORT

&duplicatekeys
&incrementkeys
&uniquepairs
&uniquekeys


=head1 AUTHOR

Jim Schueler, E<lt>jschueler@tqis.comE<gt>

=head1 SEE ALSO

L<Storable>
L<BerkeleyDB>
F<http://www.sleepycat.com>

=cut
