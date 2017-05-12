=head1 NAME

Data::MultiValuedHash - Hash whose keys have multiple ordered values

=cut

######################################################################

package Data::MultiValuedHash;
require 5.004;

# Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved.  This module
# is free software; you can redistribute it and/or modify it under the same terms
# as Perl itself.  However, I do request that this copyright information and
# credits remain attached to the file.  If you modify this module and
# redistribute a changed version then please attach a note listing the
# modifications.  This module is available "as-is" and the author can not be held
# accountable for any problems resulting from its use.

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '1.081';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

	I<none>

=head2 Nonstandard Modules

	I<none>

=head1 SYNOPSIS

	use Data::MultiValuedHash;

	$mvh = Data::MultiValuedHash->new();  # make empty, case-sensitive (norm)
	$mvh = Data::MultiValuedHash->new( 1 );  # make empty, case-insensitive
	$mvh = Data::MultiValuedHash->new( 0, {
		name => 'John',
		age => 17,
		color => 'green',
		siblings => ['Laura', 'Andrew', 'Julia'],
		pets => ['Cat', 'Bird'],
	} );  # make new with initial values, case-sensitive keys

	$mvh->store( age => 18 );  # celebrate a birthday

	$mvh->push( siblings => 'Tandy' );  # add a family member, returns 4

	$mvh->unshift( pets => ['Dog', 'Hamster'] );  # more pets

	$does_it = $mvh->exists( 'color' );  # returns true

	$name = $mvh->fetch_value( 'siblings' );  # returns 'Laura'
	$name = $mvh->fetch_value( 'siblings', 2 );  # returns 'Julia'
	$name = $mvh->fetch_value( 'siblings', -1 );  # returns 'Tandy'
	$rname = $mvh->fetch( 'siblings' );  # returns all 4 in array ref
	@names = $mvh->fetch( 'siblings' );  # returns all 4 as list

	$name = $mvh->fetch_value( 'Siblings' );  # returns nothing, wrong case
	$mv2 = Data::MultiValuedHash->new( 1, $mvh );  # conv to case inse
	$name = $mv2->fetch_value( 'Siblings' );  # returns 'Laura' this time
	$is_it = $mvh->ignores_case();  # returns false; like normal hashes
	$is_it = $mv2->ignores_case();  # returns true

	$color = $mvh->shift( 'color' );  # returns 'green'; none remain

	$animal = $mvh->pop( 'pets' );  # returns 'Bird'; three remain

	%list = $mvh->fetch_all();  # want all keys, all values
		# returns ( name => ['John'], age => [18], color => [], 
		# siblings => ['Laura', 'Andrew', 'Julia', 'Tandy'], 
		# pets => ['Dog', 'Hamster', 'Cat'] )

	%list = $mvh->fetch_first();  # want all keys, first values of each
		# returns ( name => 'John', age => 18, color => undef, 
		# siblings => 'Laura', pets => 'Dog' )

	%list = $mvh->fetch_last();  # want all keys, last values of each
		# returns ( name => 'John', age => 18, color => undef, 
		# siblings => 'Tandy', pets => 'Cat' )

	%list = $mvh->fetch_last( ['name', 'siblings'] );  # want named keys only
		# returns ( name => 'John', siblings => 'Tandy' )

	%list = $mvh->fetch_last( ['name', 'siblings'], 1 );  # want complement
		# returns ( age => 18, color => undef, pets => 'Cat' )

	$mv3 = $mvh->clone();  # make a duplicate of myself
	$mv4 = $mvh->fetch_mvh( 'pets', 1 );  # leave out the pets in this "clone"

	@list = $mv3->keys();
		# returns ('name','age','color','siblings','pets')
	$num = $mv3->keys();  # whoops, doesn't do what we expect; returns array ref
	$num = $mv3->keys_count();  # returns 5

	@list = $mv3->values();
		# returns ( 'John', 18, 'Laura', 'Andrew', 'Julia', 'Tandy', 
		# 'Dog', 'Hamster', 'Cat' )
	@num = $mv3->values_count();  # returns 9

	@list = $mvh->splice( 'Siblings', 2, 1, ['James'] );
	# replaces 'Julia' with 'James'; returns ( 'Julia' )

	$mv3->store_all( {
		songs => ['this', 'that', 'and the other'],
		pets => 'Fish',
	} );  # adds key 'songs' with values, replaces list of pets with 'fish'

	$mv3->store_value( 'pets', 'turtle' );  # replaces 'fish' with 'turtle'
	$mv3->store_value( 'pets', 'rabbit', 1 );  # pets is now ['turtle','rabbit']

	$oldval = $mv3->delete( 'color' );  # gets rid of color for good
	$rdump = $mv3->delete_all();  # return everything as hash of arrays, clear

=head1 DESCRIPTION

This Perl 5 object class implements a simple data structure that is similar to a
hash except that each key can have several values instead of just one.  There are
many places that such a structure is useful, such as database records whose
fields may be multi-valued, or when parsing results of an html form that contains
several fields with the same name.  This class can export a wide variety of
key/value subsets of its data when only some keys are needed.

While you could do tasks similar to this class by making your own hash with array
refs for values, you will need to repeat some messy-looking code everywhere you
need to use that data, creating a lot of redundant access or parsing code and 
increasing the risk of introducing errors.

One optional feature that this class provides is case-insensitive keys. 
Case-insensitivity simplifies matching form field names whose case may have been
changed by the web browser while in transit (I have seen it happen).  

=cut

######################################################################

# Names of properties for objects of this class are declared here:
my $KEY_MAIN_HASH = 'main_hash';  # this is a hash of arrays
my $KEY_CASE_INSE = 'case_inse';  # are our keys case insensitive?

######################################################################

=head1 SYNTAX

This class does not export any functions or methods, so you need to call them
using object notation.  This means using B<Class-E<gt>function()> for functions
and B<$object-E<gt>method()> for methods.  If you are inheriting this class for
your own modules, then that often means something like B<$self-E<gt>method()>. 

All method arguments and results are passed by value (where appropriate) such
that subsequent editing of them will not change values internal to the MVH
object; this is the generally accepted behaviour.

Most methods take either KEY or VALUES arguments.  KEYs are always treated as
scalars and VALUES are taken as a list.  Value lists can be passed either as an
ARRAY ref, whereupon they are internally flattened, or as an ordinary LIST.  If
the first VALUES argument is an ARRAY ref, it is interpreted as being the entire
list and subsequent arguments are ignored.  If you want to store an actual ARRAY
ref as a value, make sure to put it inside another ARRAY ref first, or it will be
flattened.

Any method which returns a list will check if it is being called in scalar or
list context.  If the context wants a scalar then the method returns its list in
an ARRAY ref; otherwise, the list is returned as a list.  This behaviour is the
same whether the returned list is an associative list (hash) or an ordinary list
(array).  Failures are returned as "undef" in scalar context and "()" in list
context.  Scalar results are returned as themselves, of course.

When case-insensitivity is used, all operations involving hash keys operate with
lowercased versions, and these are also what is stored.  The default setting of
the "ignores case" property is false, like with a normal hash.

=head1 FUNCTIONS AND METHODS

=head2 new([ CASE[, SOURCE] ])

This function creates a new Data::MultiValuedHash (or subclass) object and
returns it.  All of the method arguments are passed to initialize() as is; please
see the POD for that method for an explanation of them.

=cut

######################################################################

sub new {
	my $class = CORE::shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->initialize( @_ );
	return( $self );
}

######################################################################

=head2 initialize([ CASE[, SOURCE] ])

This method is used by B<new()> to set the initial properties of objects that it
creates.  Calling it yourself will empty the internal hash.  If you provide
arguments to this method then the first one, CASE, will initialize the
case-insensitivity attribute, and any subsequent arguments will provide initial
keys and values for the internal hash.  Nothing is returned.

The first optional argument CASE (boolean) specifies whether this object uses
case-insensitive keys; the default value is false.

The second optional argument, SOURCE is used as initial keys and values for this
object.  If it is a Hash Ref (normal or of arrays), then the store_all( SOURCE )
method is called to handle it.  If the same argument is a MVH object, then its
keys and values are similarly given to store_all( SOURCE ).  Otherwise, SOURCE 
is ignored and this object starts off empty.

=cut

######################################################################

sub initialize {
	my $self = CORE::shift( @_ );
	$self->{$KEY_MAIN_HASH} = {};
	$self->{$KEY_CASE_INSE} = 0;
	if( scalar( @_ ) ) {
		$self->{$KEY_CASE_INSE} = CORE::shift( @_ );
		my $initializer = CORE::shift( @_ );
		if( UNIVERSAL::isa($initializer,'Data::MultiValuedHash') or 
				ref($initializer) eq 'HASH' ) {
			$self->store_all( $initializer );
		} else {
			$self->_set_hash_with_nonhash_source( $initializer, @_ );
		}
	}
}

# method can be overloaded by subclass; assumes main hash empty
sub _set_hash_with_nonhash_source {
}

######################################################################

=head2 clone([ CLONE ])

This method initializes a new object to have all of the same properties of the
current object and returns it.  This new object can be provided in the optional
argument CLONE (if CLONE is an object of the same class as the current object);
otherwise, a brand new object of the current class is used.  Only object
properties recognized by Data::MultiValuedHash are set in the clone; other
properties are not changed.

=cut

######################################################################

sub clone {
	my ($self, $clone, @args) = @_;
	ref($clone) eq ref($self) or $clone = bless( {}, ref($self) );

	my $rh_main_hash = $self->{$KEY_MAIN_HASH};
	$clone->{$KEY_MAIN_HASH} = { map { ( $_, [@{$rh_main_hash->{$_}}] ) } 
		CORE::keys %{$rh_main_hash} };

	$clone->{$KEY_CASE_INSE} = $self->{$KEY_CASE_INSE};

	return( $clone );
}

######################################################################

=head2 ignores_case([ VALUE ])

This method is an accessor for the boolean "case insensitive" property of this
object, which it returns.  If VALUE is defined, this property is set to it.  

If the property is being changed from false to true, then any existing keys will 
be lowercased, and where name collisions occur, the values will be combined.
The order of these new values is determined by iterating over the original 
case-sensitive keys in the order of "sort keys()".

=cut

######################################################################

sub ignores_case {
	my $self = CORE::shift( @_ );
	if( defined( my $new_value = CORE::shift( @_ ) ) ) {
		my $old_value = $self->{$KEY_CASE_INSE};
		$self->{$KEY_CASE_INSE} = $new_value;
		if( !$old_value and $new_value ) {  # if conv from sensitiv to insens
			my $rh_main_hash = $self->{$KEY_MAIN_HASH};
			$self->{$KEY_MAIN_HASH} = {};
			$self->store_all( $rh_main_hash );
		}
	}
	return( $self->{$KEY_CASE_INSE} );
}

######################################################################

=head2 keys()

This method returns a list of all this object's keys.

=cut

######################################################################

sub keys {
	my $self = CORE::shift( @_ );
	my @keys_list = CORE::keys %{$self->{$KEY_MAIN_HASH}};
	return( wantarray ? @keys_list : \@keys_list );
}

######################################################################

=head2 keys_count()

This method returns a count of this object's keys.

=cut

######################################################################

sub keys_count {
	my $self = CORE::shift( @_ );
	return( scalar( CORE::keys %{$self->{$KEY_MAIN_HASH}} ) );
}

######################################################################

=head2 values()

This method returns a flattened list of all this object's values.

=cut

######################################################################

sub values {
	my $self = CORE::shift( @_ );
	my @values_list = map { @{$_} } CORE::values %{$self->{$KEY_MAIN_HASH}};
	return( wantarray ? @values_list : \@values_list );
}

######################################################################

=head2 values_count()

This method returns a count of all this object's values.

=cut

######################################################################

sub values_count {
	my $self = CORE::shift( @_ );
	my $count = 0;
	map { $count += scalar( @{$_} ) } CORE::values %{$self->{$KEY_MAIN_HASH}};
	return( $count );
}

######################################################################

=head2 exists( KEY )

This method returns true if KEY is in the hash, although it may not have any
values.

=cut

######################################################################

sub exists {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	defined( $key ) or $key = '';
	return( CORE::exists( $self->{$KEY_MAIN_HASH}->{$key} ) );
}

######################################################################

=head2 count( KEY )

This method returns a count of the values that KEY has.  It returns failure if
KEY doesn't exist.

=cut

######################################################################

sub count {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	defined( $key ) or $key = '';
	CORE::exists( $self->{$KEY_MAIN_HASH}->{$key} ) or return( undef );
	return( scalar( @{$self->{$KEY_MAIN_HASH}->{$key}} ) );
}

######################################################################

=head2 fetch_value( KEY[, INDEX] )

This method returns a single value of KEY, which is at INDEX position in the
internal array of values; the default INDEX is 0.  It returns failure if KEY
doesn't exist.

=cut

######################################################################

sub fetch_value {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	defined( $key ) or $key = '';
	CORE::exists( $self->{$KEY_MAIN_HASH}->{$key} ) or return( undef );
	my $index = CORE::shift( @_ ) || 0;
	return( $self->{$KEY_MAIN_HASH}->{$key}->[$index] );
}

######################################################################

=head2 fetch( KEY[, INDEXES] )

This method returns a list of all values that KEY has.  It returns failure if KEY
doesn't exist.  The first optional argument, INDEXES, is an array ref that specifies 
a subset of all this key's values that we want returned instead of all of them.

=cut

######################################################################

sub fetch {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	defined( $key ) or $key = '';
	CORE::exists( $self->{$KEY_MAIN_HASH}->{$key} ) or 
		return( wantarray ? () : undef );
	my @values = @{$self->{$KEY_MAIN_HASH}->{$key}};
	if( defined( $_[0] ) ) {
		my @indexes = 
			ref( $_[0] ) eq 'ARRAY' ? @{CORE::shift( @_ )} : CORE::shift( @_ );
		my %indexes = map { ($_ + 0, 1) } @indexes;  # clean up input
		@indexes = sort (CORE::keys %indexes);
		@values = @values[@indexes];
	}
	return( wantarray ? @values : \@values );
}

######################################################################

=head2 fetch_hash([ INDEX[, KEYS[, COMPLEMENT]] ])

This method returns a hash with all this object's keys and a single value of 
each key, which is at INDEX position in the internal array of values for the 
key; the default INDEX is 0.  The first optional argument, KEYS, is an array ref 
that specifies a subset of all this object's keys that we want returned. If the 
second optional boolean argument, COMPLEMENT, is true, then the complement of 
the keys listed in KEYS is returned instead.

=cut

######################################################################

sub fetch_hash {
	my $self = CORE::shift( @_ );
	my $index = CORE::shift( @_ ) || 0;
	my $rh_main_hash = $self->{$KEY_MAIN_HASH};
	my %hash_copy = map { ( $_, $rh_main_hash->{$_}->[$index] ) } 
		CORE::keys %{$rh_main_hash};
	if( defined( $_[0] ) ) {
		$self->_reduce_hash_to_subset( \%hash_copy, @_ );
	}
	return( wantarray ? %hash_copy : \%hash_copy );
}

######################################################################

=head2 fetch_first([ KEYS[, COMPLEMENT] ])

This method returns a hash with all this object's keys, but only the first value
for each key.  The first optional argument, KEYS, is an array ref that specifies
a subset of all this object's keys that we want returned. If the second optional
boolean argument, COMPLEMENT, is true, then the complement of the keys listed in
KEYS is returned instead.

=cut

######################################################################

sub fetch_first {
	my $self = CORE::shift( @_ );
	my $rh_output = $self->fetch_hash( 0, @_ );
	return( wantarray ? %{$rh_output} : $rh_output );
}

######################################################################

=head2 fetch_last([ KEYS[, COMPLEMENT] ])

This method returns a hash with all this object's keys, but only the last value
for each key.  The first optional argument, KEYS, is an array ref that specifies
a subset of all this object's keys that we want returned. If the second optional
boolean argument, COMPLEMENT, is true, then the complement of the keys listed in
KEYS is returned instead.

=cut

######################################################################

sub fetch_last {
	my $self = CORE::shift( @_ );
	my $rh_output = $self->fetch_hash( -1, @_ );
	return( wantarray ? %{$rh_output} : $rh_output );
}

######################################################################

=head2 fetch_all([ KEYS[, COMPLEMENT[, INDEXES]] ])

This method returns a hash with all this object's keys and values.  The values
for each key are contained in an ARRAY ref.  The first optional argument, KEYS,
is an array ref that specifies a subset of all this object's keys that we want
returned.  If the second optional boolean argument, COMPLEMENT, is true, then the
complement of the keys listed in KEYS is returned instead.  The third optional 
argument, INDEXES, is an array ref that specifies a subset of all of each key's 
values that we want returned instead of all of them.

=cut

######################################################################

sub fetch_all {
	my $self = CORE::shift( @_ );
	my $rh_main_hash = $self->{$KEY_MAIN_HASH};
	my %hash_copy = 
		map { ( $_, [@{$rh_main_hash->{$_}}] ) } CORE::keys %{$rh_main_hash};
	if( defined( $_[0] ) ) {
		$self->_reduce_hash_to_subset( \%hash_copy, @_ );
	}
	if( defined( $_[2] ) ) {
		my @indexes = ref( $_[2] ) eq 'ARRAY' ? @{$_[2]} : $_[2];
		my %indexes = map { ($_ + 0, 1) } @indexes;  # clean up input
		@indexes = sort (CORE::keys %indexes);
		%hash_copy = map { ($_, [@{$hash_copy{$_}}[@indexes]]) } 
			CORE::keys %hash_copy;
	}
	return( wantarray ? %hash_copy : \%hash_copy );
}

######################################################################

=head2 fetch_mvh([ KEYS[, COMPLEMENT[, INDEXES]] ])

This method returns a new MVH object with all or a subset of this object's keys
and values. It has the same calling conventions as fetch_all() except that an MVH
object is returned instead of a literal hash.  The case-insensitivity attribute 
of the new MVH is the same as the current one.

=cut

######################################################################

sub fetch_mvh {
	my $self = CORE::shift( @_ );
	my $new_mvh = bless( {}, ref($self) );
	$new_mvh->{$KEY_MAIN_HASH} = $self->fetch_all( @_ );
	$new_mvh->{$KEY_CASE_INSE} = $self->{$KEY_CASE_INSE};
	return( $new_mvh );
}

######################################################################

=head2 store_value( KEY, VALUE[, INDEX] )

This method adds a new KEY to this object, if it doesn't already exist.  The 
VALUE replaces any that may have existed before at INDEX position in the 
internal array of values; the default INDEX is 0.  This method returns the new 
count of values that KEY has, which may be more than one greater than before.

=cut

######################################################################

sub store_value {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	my $value = CORE::shift( @_ );
	my $index = CORE::shift( @_ ) || 0;
	$self->{$KEY_MAIN_HASH}->{$key} ||= [];
	$self->{$KEY_MAIN_HASH}->{$key}->[$index] = $value;
	return( scalar( @{$self->{$KEY_MAIN_HASH}->{$key}} ) );
}

######################################################################

=head2 store( KEY, VALUES )

This method adds a new KEY to this object, if it doesn't already exist. The
VALUES replace any that may have existed before.  This method returns the new
count of values that KEY has.  The best way to get a key which has no values is
to pass an empty ARRAY ref as the VALUES.

=cut

######################################################################

sub store {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	my @values = (ref( $_[0] ) eq 'ARRAY') ? @{CORE::shift( @_ )} : @_;
	$self->{$KEY_MAIN_HASH}->{$key} = \@values;
	return( scalar( @{$self->{$KEY_MAIN_HASH}->{$key}} ) );
}

######################################################################

=head2 store_all( HASH )

This method takes one argument, HASH, which is an associative list or hash ref
or MVH object containing new keys and values to store in this object.  The value
associated with each key can be either scalar or an array.  Symantics are the
same as for calling store() multiple times, once for each KEY. Existing keys and
values with the same names are replaced.  New keys are added in the order of 
"sort CORE::keys %hash".  This method returns a count of new keys added.

=cut

######################################################################

sub store_all {
	my $self = CORE::shift( @_ );
	my %new = UNIVERSAL::isa( $_[0], 'Data::MultiValuedHash' ) ? 
		(%{CORE::shift( @_ )->{$KEY_MAIN_HASH}}) : 
		(ref( $_[0] ) eq 'HASH') ? (%{CORE::shift( @_ )}) : @_;
	my $rh_main_hash = $self->{$KEY_MAIN_HASH};
	my $case_inse = $self->{$KEY_CASE_INSE};
	foreach my $key (sort (CORE::keys %new)) {
		my @values = (ref($new{$key}) eq 'ARRAY') ? @{$new{$key}} : $new{$key};
		$key = lc($key) if( $case_inse );
		$rh_main_hash->{$key} = \@values;
	}
	return( scalar( CORE::keys %new ) );
}

######################################################################

=head2 push( KEY, VALUES )

This method adds a new KEY to this object, if it doesn't already exist. The
VALUES are appended to the list of any that existed before.  This method returns
the new count of values that KEY has.

=cut

######################################################################

sub push {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	defined( $key ) or $key = '';
	my @values = (ref( $_[0] ) eq 'ARRAY') ? @{CORE::shift( @_ )} : @_;
	$self->{$KEY_MAIN_HASH}->{$key} ||= [];
	CORE::push( @{$self->{$KEY_MAIN_HASH}->{$key}}, @values );
	return( scalar( @{$self->{$KEY_MAIN_HASH}->{$key}} ) );
}

######################################################################

=head2 unshift( KEY, VALUES )

This method adds a new KEY to this object, if it doesn't already exist. The
VALUES are prepended to the list of any that existed before.  This method returns
the new count of values that KEY has.

=cut

######################################################################

sub unshift {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	my @values = (ref( $_[0] ) eq 'ARRAY') ? @{CORE::shift( @_ )} : @_;
	$self->{$KEY_MAIN_HASH}->{$key} ||= [];
	CORE::unshift( @{$self->{$KEY_MAIN_HASH}->{$key}}, @values );
	return( scalar( @{$self->{$KEY_MAIN_HASH}->{$key}} ) );
}

######################################################################

=head2 pop( KEY )

This method removes the last value associated with KEY and returns it.  It
returns failure if KEY doesn't exist.

=cut

######################################################################

sub pop {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	CORE::exists( $self->{$KEY_MAIN_HASH}->{$key} ) or return( undef );
	return( CORE::pop( @{$self->{$KEY_MAIN_HASH}->{$key}} ) );
}

######################################################################

=head2 shift( KEY )

This method removes the last value associated with KEY and returns it.  It
returns failure if KEY doesn't exist.

=cut

######################################################################

sub shift {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	CORE::exists( $self->{$KEY_MAIN_HASH}->{$key} ) or return( undef );
	return( CORE::shift( @{$self->{$KEY_MAIN_HASH}->{$key}} ) );
}

######################################################################

=head2 splice( KEY, OFFSET[, LENGTH[, VALUES]] )

This method adds a new KEY to this object, if it doesn't already exist. The
values for KEY at index positions designated by OFFSET and LENGTH are removed,
and replaced with any VALUES that there may be.  This method returns the elements
removed from the list of values for KEY, which grows or shrinks as necessary. If
LENGTH is omitted, the method returns everything from OFFSET onward.

=cut

######################################################################

sub splice {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	my $offset = CORE::shift( @_ ) || 0;
	my $length = CORE::shift( @_ );
	my @values = (ref( $_[0] ) eq 'ARRAY') ? @{CORE::shift( @_ )} : @_;
	$self->{$KEY_MAIN_HASH}->{$key} ||= [];
	# yes, an undef or () for $length is diff than it not being there at all
	my @output = defined( $length ) ? CORE::splice( 
		@{$self->{$KEY_MAIN_HASH}->{$key}}, $offset, $length, @values ) : 
		CORE::splice( @{$self->{$KEY_MAIN_HASH}->{$key}}, $offset );
	return( wantarray ? @output : \@output );
}

######################################################################

=head2 delete( KEY )

This method removes KEY and returns its values.  It returns failure if KEY
doesn't previously exist.

=cut

######################################################################

sub delete {
	my $self = CORE::shift( @_ );
	my $key = $self->{$KEY_CASE_INSE} ? lc(CORE::shift(@_)) : CORE::shift(@_);
	CORE::exists( $self->{$KEY_MAIN_HASH}->{$key} ) or 
		return( wantarray ? () : undef );
	my $ra_values = CORE::delete( $self->{$KEY_MAIN_HASH}->{$key} );
	return( wantarray ? @{$ra_values} : $ra_values );
}

######################################################################

=head2 delete_all()

This method deletes all this object's keys and values and returns them in a hash.
 The values for each key are contained in an ARRAY ref.

=cut

######################################################################

sub delete_all {
	my $self = CORE::shift( @_ );
	my $rh_main_hash = $self->{$KEY_MAIN_HASH};
	$self->{$KEY_MAIN_HASH} = {};
	return( wantarray ? %{$rh_main_hash} : $rh_main_hash );
}

######################################################################

=head2 batch_new( CASE, SOURCE[, *] )

This batch function creates a list of new Data::MultiValuedHash (or subclass)
objects and returns them.  The symantecs are like calling new() multiple times,
except that the argument SOURCE is required.  SOURCE is an array and this
function creates as many MVH objects as there are elements in SOURCE.  The list 
is returned as an array ref in scalar context and a list in list context.
CASE defaults to false if undefined.  Any arguments following SOURCE are passed 
to new() as is.

=cut

######################################################################

sub batch_new {
	my $class = CORE::shift( @_ );
	my $case_inse = CORE::shift( @_ ) || 0;
	my @initializers = 
		ref($_[0]) eq 'ARRAY' ? @{CORE::shift(@_)} : CORE::shift(@_);
	my @new_mvh = map { $class->new( $case_inse, $_, @_ ) } @initializers;
	return( wantarray ? @new_mvh : \@new_mvh );
}

######################################################################
# Call: $self->_reduce_hash_from_subset( $rh_hash, $ra_keys, $is_compl )
# This method takes a hash reference and filters keys and associated 
# values from it.  The first argument, $rh_hash, is changed in place.  
# The second argument $ra_keys is a list to keep; however, if the third 
# boolean argument $is_compl is true, then the complement of $ra_keys is 
# kept instead.

sub _reduce_hash_to_subset {    # meant only for internal use
	my $self = CORE::shift( @_ );
	my $rh_hash_copy = CORE::shift( @_ );
	my $ra_keys = CORE::shift( @_ );
	$ra_keys = (ref($ra_keys) eq 'HASH') ? (CORE::keys %{$ra_keys}) : 
		UNIVERSAL::isa($ra_keys,'Data::MultiValuedHash') ? $ra_keys->keys() : 
		(ref($ra_keys) ne 'ARRAY') ? [$ra_keys] : $ra_keys;
	my $case_inse = $self->{$KEY_CASE_INSE};
	my %spec_keys = map { ( $case_inse ? lc($_) : $_ => 1 ) } @{$ra_keys};
	if( CORE::shift( @_ ) ) {   # want complement of keys list
		%{$rh_hash_copy} = map { !$spec_keys{$_} ? 
			($_ => $rh_hash_copy->{$_}) : () } CORE::keys %{$rh_hash_copy};
	} else {
		%{$rh_hash_copy} = map { $spec_keys{$_} ? 
			($_ => $rh_hash_copy->{$_}) : () } CORE::keys %{$rh_hash_copy};
	}
}

######################################################################

1;
__END__

=head1 METHOD RELATIONSHIP OVERVIEW

A MultiValuedHash can be seen conceivably as a table where keys are row indices 
and each value for the key is a column; the columns indices are in value arrays.

When fetching data, we could remove either one cell at a time, or a whole row or 
a whole column, or a block of cells making parts of a row and or column.  This 
diagram indicates the data type that would be returned by methods corresponding 
to different fetch types:

	      1 v    n v   all v
	1   k scalar array array
	n   k hash   mvh   mvh
	all k hash   mvh   mvh

The following method list indicates the return types of all the standard methods, 
and how they relate to the conceptual diagram.  Pay particular attention to the 
fetch methods.

	array  = keys()
	scalar = keys_count()
	array  = values()
	scalar = values_count()

	scalar = exists( KEY )

	scalar = count( KEY )

	scalar = fetch_value( KEY[, INDEX] ) - index=0
	array  = fetch( KEY[, INDEXES] ) - indexes=all
	hash   = fetch_hash( INDEX[, KEYS[, COMPLEMENT]] ) - index=0
		hash = fetch_first([ KEYS[, COMPLEMENT] ]) - index=0
		hash = fetch_last([ KEYS[, COMPLEMENT] ])  - index=-1
	mvh    = fetch_all([ KEYS[, COMPLEMENT[, INDEXES ]] ]) - keys=all,ind=all
		mvh = fetch_mvh([ KEYS[, COMPLEMENT[, INDEXES ]] ]) - keys=all,ind=all

	store_value( KEY, VALUE[, INDEX] ) - index=0
	store( KEY, VALUES )
	store_all( HASH )

	push( KEY, VALUES )

	unshift( KEY, VALUES )

	scalar = pop( KEY )

	scalar = shift( KEY )

	array = splice( KEY, OFFSET, LENGTH, VALUES )

	array = delete( KEY )
	mvh   = delete_all()

=head1 AUTHOR

Copyright (c) 1999-2003, Darren R. Duncan.  All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.  However, I do request that this copyright information and
credits remain attached to the file.  If you modify this module and
redistribute a changed version then please attach a note listing the
modifications.  This module is available "as-is" and the author can not be held
accountable for any problems resulting from its use.

I am always interested in knowing how my work helps others, so if you put this
module to use in any of your own products or services then I would appreciate
(but not require) it if you send me the website url for said product or
service, so I know who you are.  Also, if you make non-proprietary changes to
the module because it doesn't work the way you need, and you are willing to
make these freely available, then please send me a copy so that I can roll
desirable changes into the main release.

Address comments, suggestions, and bug reports to B<perl@DarrenDuncan.net>.

=head1 CREDITS

Thanks to Johan Vromans <jvromans@squirrel.nl> for suggesting the split of my old
module "CGI::HashOfArrays" into the two current ones, "Data::MultiValuedHash" and
"CGI::MultiValuedHash".  This took care of a longstanding logistical problem
concerning whether the module was a generic data structure or a tool for
encoding/decoding CGI data.

Thanks to Steve Benson <steve.benson@stanford.edu> for suggesting POD
improvements in regards to the case-insensitivity feature, so the documentation
is easier to understand.

Thanks to Geir Johannessen <geir.johannessen@nextra.com> for alerting me to 
several "ambiguous call" warnings.

Thanks to Jonathan Snyder <jonathan@mail.method.com> for alerting me to some 
more "ambiguous call" warnings.

=head1 SEE ALSO

perl(1), CGI::MultiValuedHash, HTML::FormTemplate, CGI::Portable.

=cut
