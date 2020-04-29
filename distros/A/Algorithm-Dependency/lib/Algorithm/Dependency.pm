package Algorithm::Dependency; # git description: v1.111-8-g2fb772e
# ABSTRACT: Base class for implementing various dependency trees

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod Typical Usage: Ordering based on dependency requirements
#pod   
#pod   use Algorithm::Dependency::Ordered;
#pod   use Algorithm::Dependency::Source::HoA;
#pod   
#pod   my $deps = {
#pod     core  => [ ],
#pod     a     => [ 'core' ],
#pod     b     => [ 'a' ]
#pod     this  => [ ],
#pod     that  => [ ],
#pod   };
#pod   my $deps_source = Algorithm::Dependency::Source::HoA->new( $deps );
#pod
#pod   my $dep = Algorithm::Dependency::Ordered->new(
#pod     source   => $deps_source,
#pod     selected => [ 'this', 'that' ], # Items we have processed elsewhere or have already satisfied
#pod   )
#pod   or die 'Failed to set up dependency algorithm';
#pod
#pod   my $also = $dep->schedule_all();
#pod   # Returns: ['core', 'a', 'b'] -- ie: installation-order. Whereas using base
#pod   # Algorithm::Dependency would return sorted ['a', 'b', 'core']
#pod
#pod   my $also = $dep->schedule( 'b' );
#pod   # Returns: ['core', 'a', 'b'] -- installation order, including ourselves
#pod
#pod   my $also = $dep->depends( 'b' );
#pod   # Returns: ['a', 'core'] -- sorted order, not including ourselves
#pod
#pod Base Classes
#pod
#pod   use Algorithm::Dependency;
#pod   use Algorithm::Dependency::Source::File;
#pod   
#pod   # Load the data from a simple text file
#pod   my $data_source = Algorithm::Dependency::Source::File->new( 'foo.txt' );
#pod   
#pod   # Create the dependency object, and indicate the items that are already
#pod   # selected/installed/etc in the database
#pod   my $dep = Algorithm::Dependency->new(
#pod       source   => $data_source,
#pod       selected => [ 'This', 'That' ]
#pod   ) or die 'Failed to set up dependency algorithm';
#pod   
#pod   # For the item 'Foo', find out the other things we also have to select.
#pod   # This WON'T include the item we selected, 'Foo'.
#pod   my $also = $dep->depends( 'Foo' );
#pod   print $also
#pod   	? "By selecting 'Foo', you are also selecting the following items: "
#pod   		. join( ', ', @$also )
#pod   	: "Nothing else to select for 'Foo'";
#pod   
#pod   # Find out the order we need to act on the items in.
#pod   # This WILL include the item we selected, 'Foo'.
#pod   my $schedule = $dep->schedule( 'Foo' );
#pod
#pod =head1 DESCRIPTION
#pod
#pod Algorithm::Dependency is a framework for creating simple read-only
#pod dependency hierarchies, where you have a set of items that rely on other
#pod items in the set, and require actions on them as well.
#pod
#pod Despite the most visible of these being software installation systems like
#pod the CPAN installer, or Debian apt-get, they are useful in other situations.
#pod This module intentionally uses implementation-neutral words, to avoid
#pod confusion.
#pod
#pod =head2 Terminology
#pod
#pod The term C<ITEM> refers to a single entity, such as a single software
#pod package, in the overall set of possible entities. Internally, this is a
#pod fairly simple object. See L<Algorithm::Dependency::Item> for details.
#pod
#pod The term C<SELECT> means that a particular item, for your purposes, has
#pod already been acted up in the required way. For example, if the software
#pod package had already been installed, and didn't need to be re-installed,
#pod it would be C<SELECTED>.
#pod
#pod The term C<SOURCE> refers to a location that contains the master set of
#pod items. This will be very application specific, and might be a flat file,
#pod some form of database, the list of files in a folder, or generated
#pod dynamically.
#pod
#pod =head2 General Description
#pod
#pod =for stopwords versioned
#pod
#pod Algorithm::Dependency implements algorithms relating to dependency
#pod hierarchies. To use this framework, all you need is a source for the master
#pod list of all the items, and a list of those already selected. If your
#pod dependency hierarchy doesn't require the concept of items that are already
#pod selected, simply don't pass anything to the constructor for it.
#pod
#pod Please note that the class Algorithm::Dependency does NOT implement an
#pod ordering, for speed and simplicity reasons. That is, the C<schedule> it
#pod provides is not in any particular order. If item 'A' depends on item 'B',
#pod it will not place B before A in the schedule. This makes it unsuitable for
#pod things like software installers, as they typically would need B to be
#pod installed before A, or the installation of A would fail.
#pod
#pod For dependency hierarchies requiring the items to be acted on in a particular
#pod order, either top down or bottom up, see L<Algorithm::Dependency::Ordered>.
#pod It should be more applicable for your needs. This is the the subclass you
#pod would probably use to implement a simple ( non-versioned ) package
#pod installation system. Please note that an ordered hierarchy has additional
#pod constraints. For example, circular dependencies ARE legal in a
#pod non-ordered hierarchy, but ARE NOT legal in an ordered hierarchy.
#pod
#pod =head2 Extending
#pod
#pod A module for creating a source from a simple flat file is included. For
#pod details see L<Algorithm::Dependency::Source::File>. Information on creating
#pod a source for your particular use is in L<Algorithm::Dependency::Source>.
#pod
#pod =head1 METHODS
#pod
#pod =cut

use 5.005;
use strict;
use Params::Util qw{_INSTANCE _ARRAY};
use Algorithm::Dependency::Item   ();
use Algorithm::Dependency::Source ();

our $VERSION = '1.112';


#####################################################################
# Constructor

#pod =pod
#pod
#pod =head2 new %args
#pod
#pod The constructor creates a new context object for the dependency algorithms to
#pod act in. It takes as argument a series of options for creating the object.
#pod
#pod =over 4
#pod
#pod =item source => $Source
#pod
#pod The only compulsory option is the source of the dependency items. This is
#pod an object of a subclass of L<Algorithm::Dependency::Source>. In practical terms,
#pod this means you will create the source object before creating the
#pod Algorithm::Dependency object.
#pod
#pod =item selected => [ 'A', 'B', 'C', etc... ]
#pod
#pod The C<selected> option provides a list of those items that have already been
#pod 'selected', acted upon, installed, or whatever. If another item depends on one
#pod in this list, we don't have to include it in the output of the C<schedule> or
#pod C<depends> methods.
#pod
#pod =item ignore_orphans => 1
#pod
#pod Normally, the item source is expected to be largely perfect and error free.
#pod An 'orphan' is an item name that appears as a dependency of another item, but
#pod doesn't exist, or has been deleted.
#pod
#pod By providing the C<ignore_orphans> flag, orphans are simply ignored. Without
#pod the C<ignore_orphans> flag, an error will be returned if an orphan is found.
#pod
#pod =back
#pod
#pod The C<new> constructor returns a new Algorithm::Dependency object on success,
#pod or C<undef> on error.
#pod
#pod =cut

sub new {
	my $class  = shift;
	my %args   = @_;
	my $source = _INSTANCE($args{source}, 'Algorithm::Dependency::Source')
		or return undef;

	# Create the object
	my $self = bless {
		source   => $source, # Source object
		selected => {},
		}, $class;

	# Were we given the 'ignore_orphans' flag?
	if ( $args{ignore_orphans} ) {
		$self->{ignore_orphans} = 1;
	}

	# Done, unless we have been given some selected items
	_ARRAY($args{selected}) or return $self;

	# Make sure each of the selected ids exists
	my %selected = ();
	foreach my $id ( @{ $args{selected} } ) {
		# Does the item exist?
		return undef unless $source->item($id);

		# Is it a duplicate
		return undef if $selected{$id};

		# Add to the selected index
		$selected{$id} = 1;
	}

	$self->{selected} = \%selected;
	$self;
}





#####################################################################
# Basic methods

#pod =pod
#pod
#pod =head2 source
#pod
#pod The C<source> method retrieves the L<Algorithm::Dependency::Source> object
#pod for the algorithm context.
#pod
#pod =cut

sub source { $_[0]->{source} }

#pod =pod
#pod
#pod =head2 selected_list
#pod
#pod The C<selected_list> method returns, as a list and in alphabetical order,
#pod the list of the names of the selected items.
#pod
#pod =cut

sub selected_list { sort keys %{$_[0]->{selected}} }

#pod =pod
#pod
#pod =head2 selected $name
#pod
#pod Given an item name, the C<selected> method will return true if the item is
#pod selected, false is not, or C<undef> if the item does not exist, or an error
#pod occurs.
#pod
#pod =cut

sub selected { $_[0]->{selected}->{$_[1]} }

#pod =pod
#pod
#pod =head2 item $name
#pod
#pod The C<item> method fetches and returns the item object, as specified by the
#pod name argument.
#pod
#pod Returns an L<Algorithm::Dependency::Item> object on success, or C<undef> if
#pod an item does not exist for the argument provided.
#pod
#pod =cut

sub item { $_[0]->{source}->item($_[1]) }





#####################################################################
# Main algorithm methods

#pod =pod
#pod
#pod =head2 depends $name1, ..., $nameN
#pod
#pod Given a list of one or more item names, the C<depends> method will return
#pod a reference to an array containing a list of the names of all the OTHER
#pod items that also have to be selected to meet dependencies.
#pod
#pod That is, if item A depends on B and C then the C<depends> method would
#pod return a reference to an array with B and C. ( C<[ 'B', 'C' ]> )
#pod
#pod If multiple item names are provided, the same applies. The list returned
#pod will not contain duplicates.
#pod
#pod The method returns a reference to an array of item names on success, a
#pod reference to an empty array if no other items are needed, or C<undef>
#pod on error.
#pod
#pod NOTE: The result of C<depends> is ordered by an internal C<sort>
#pod irrespective of the ordering provided by the dependency handler.  Use
#pod L<Algorithm::Dependency::Ordered> and C<schedule> to use the most
#pod common ordering (process sequence)
#pod
#pod =cut

sub depends {
	my $self    = shift;
	my @stack   = @_ or return undef;
	my @depends = ();
	my %checked = ();

	# Process the stack
	while ( my $id = shift @stack ) {
		# Does the id exist?
		my $Item = $self->{source}->item($id)
		or $self->{ignore_orphans} ? next : return undef;

		# Skip if selected or checked
		next if $checked{$id};

		# Add its depends to the stack
		push @stack, $Item->depends;
		$checked{$id} = 1;

		# Add anything to the final output that wasn't one of
		# the original input.
		unless ( scalar grep { $id eq $_ } @_ ) {
			push @depends, $id;
		}
	}

	# Remove any items already selected
	my $s = $self->{selected};
	return [ sort grep { ! $s->{$_} } @depends ];
}

#pod =pod
#pod
#pod =head2 schedule $name1, ..., $nameN
#pod
#pod Given a list of one or more item names, the C<depends> method will
#pod return, as a reference to an array, the ordered list of items you
#pod should act upon in whichever order this particular dependency handler
#pod uses - see L<Algorithm::Dependency::Ordered> for one that implements
#pod the most common ordering (process sequence).
#pod
#pod This would be the original names provided, plus those added to satisfy
#pod dependencies, in the preferred order of action. For the normal algorithm,
#pod where order it not important, this is alphabetical order. This makes it
#pod easier for someone watching a program operate on the items to determine
#pod how far you are through the task and makes any logs easier to read.
#pod
#pod If any of the names you provided in the arguments is already selected, it
#pod will not be included in the list.
#pod
#pod The method returns a reference to an array of item names on success, a
#pod reference to an empty array if no items need to be acted upon, or C<undef>
#pod on error.
#pod
#pod =cut

sub schedule {
	my $self  = shift;
	my @items = @_ or return undef;

	# Get their dependencies
	my $depends = $self->depends( @items ) or return undef;

	# Now return a combined list, removing any items already selected.
	# We are allowed to return an empty list.
	my $s = $self->{selected};
	return [ sort grep { ! $s->{$_} } @items, @$depends ];
}

#pod =pod
#pod
#pod =head2 schedule_all;
#pod
#pod The C<schedule_all> method acts the same as the C<schedule> method, but 
#pod returns a schedule that selected all the so-far unselected items.
#pod
#pod =cut

sub schedule_all {
	my $self = shift;
	$self->schedule( map { $_->id } $self->source->items );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Dependency - Base class for implementing various dependency trees

=head1 VERSION

version 1.112

=head1 SYNOPSIS

Typical Usage: Ordering based on dependency requirements

  use Algorithm::Dependency::Ordered;
  use Algorithm::Dependency::Source::HoA;
  
  my $deps = {
    core  => [ ],
    a     => [ 'core' ],
    b     => [ 'a' ]
    this  => [ ],
    that  => [ ],
  };
  my $deps_source = Algorithm::Dependency::Source::HoA->new( $deps );

  my $dep = Algorithm::Dependency::Ordered->new(
    source   => $deps_source,
    selected => [ 'this', 'that' ], # Items we have processed elsewhere or have already satisfied
  )
  or die 'Failed to set up dependency algorithm';

  my $also = $dep->schedule_all();
  # Returns: ['core', 'a', 'b'] -- ie: installation-order. Whereas using base
  # Algorithm::Dependency would return sorted ['a', 'b', 'core']

  my $also = $dep->schedule( 'b' );
  # Returns: ['core', 'a', 'b'] -- installation order, including ourselves

  my $also = $dep->depends( 'b' );
  # Returns: ['a', 'core'] -- sorted order, not including ourselves

Base Classes

  use Algorithm::Dependency;
  use Algorithm::Dependency::Source::File;
  
  # Load the data from a simple text file
  my $data_source = Algorithm::Dependency::Source::File->new( 'foo.txt' );
  
  # Create the dependency object, and indicate the items that are already
  # selected/installed/etc in the database
  my $dep = Algorithm::Dependency->new(
      source   => $data_source,
      selected => [ 'This', 'That' ]
  ) or die 'Failed to set up dependency algorithm';
  
  # For the item 'Foo', find out the other things we also have to select.
  # This WON'T include the item we selected, 'Foo'.
  my $also = $dep->depends( 'Foo' );
  print $also
  	? "By selecting 'Foo', you are also selecting the following items: "
  		. join( ', ', @$also )
  	: "Nothing else to select for 'Foo'";
  
  # Find out the order we need to act on the items in.
  # This WILL include the item we selected, 'Foo'.
  my $schedule = $dep->schedule( 'Foo' );

=head1 DESCRIPTION

Algorithm::Dependency is a framework for creating simple read-only
dependency hierarchies, where you have a set of items that rely on other
items in the set, and require actions on them as well.

Despite the most visible of these being software installation systems like
the CPAN installer, or Debian apt-get, they are useful in other situations.
This module intentionally uses implementation-neutral words, to avoid
confusion.

=head2 Terminology

The term C<ITEM> refers to a single entity, such as a single software
package, in the overall set of possible entities. Internally, this is a
fairly simple object. See L<Algorithm::Dependency::Item> for details.

The term C<SELECT> means that a particular item, for your purposes, has
already been acted up in the required way. For example, if the software
package had already been installed, and didn't need to be re-installed,
it would be C<SELECTED>.

The term C<SOURCE> refers to a location that contains the master set of
items. This will be very application specific, and might be a flat file,
some form of database, the list of files in a folder, or generated
dynamically.

=head2 General Description

=for stopwords versioned

Algorithm::Dependency implements algorithms relating to dependency
hierarchies. To use this framework, all you need is a source for the master
list of all the items, and a list of those already selected. If your
dependency hierarchy doesn't require the concept of items that are already
selected, simply don't pass anything to the constructor for it.

Please note that the class Algorithm::Dependency does NOT implement an
ordering, for speed and simplicity reasons. That is, the C<schedule> it
provides is not in any particular order. If item 'A' depends on item 'B',
it will not place B before A in the schedule. This makes it unsuitable for
things like software installers, as they typically would need B to be
installed before A, or the installation of A would fail.

For dependency hierarchies requiring the items to be acted on in a particular
order, either top down or bottom up, see L<Algorithm::Dependency::Ordered>.
It should be more applicable for your needs. This is the the subclass you
would probably use to implement a simple ( non-versioned ) package
installation system. Please note that an ordered hierarchy has additional
constraints. For example, circular dependencies ARE legal in a
non-ordered hierarchy, but ARE NOT legal in an ordered hierarchy.

=head2 Extending

A module for creating a source from a simple flat file is included. For
details see L<Algorithm::Dependency::Source::File>. Information on creating
a source for your particular use is in L<Algorithm::Dependency::Source>.

=head1 METHODS

=head2 new %args

The constructor creates a new context object for the dependency algorithms to
act in. It takes as argument a series of options for creating the object.

=over 4

=item source => $Source

The only compulsory option is the source of the dependency items. This is
an object of a subclass of L<Algorithm::Dependency::Source>. In practical terms,
this means you will create the source object before creating the
Algorithm::Dependency object.

=item selected => [ 'A', 'B', 'C', etc... ]

The C<selected> option provides a list of those items that have already been
'selected', acted upon, installed, or whatever. If another item depends on one
in this list, we don't have to include it in the output of the C<schedule> or
C<depends> methods.

=item ignore_orphans => 1

Normally, the item source is expected to be largely perfect and error free.
An 'orphan' is an item name that appears as a dependency of another item, but
doesn't exist, or has been deleted.

By providing the C<ignore_orphans> flag, orphans are simply ignored. Without
the C<ignore_orphans> flag, an error will be returned if an orphan is found.

=back

The C<new> constructor returns a new Algorithm::Dependency object on success,
or C<undef> on error.

=head2 source

The C<source> method retrieves the L<Algorithm::Dependency::Source> object
for the algorithm context.

=head2 selected_list

The C<selected_list> method returns, as a list and in alphabetical order,
the list of the names of the selected items.

=head2 selected $name

Given an item name, the C<selected> method will return true if the item is
selected, false is not, or C<undef> if the item does not exist, or an error
occurs.

=head2 item $name

The C<item> method fetches and returns the item object, as specified by the
name argument.

Returns an L<Algorithm::Dependency::Item> object on success, or C<undef> if
an item does not exist for the argument provided.

=head2 depends $name1, ..., $nameN

Given a list of one or more item names, the C<depends> method will return
a reference to an array containing a list of the names of all the OTHER
items that also have to be selected to meet dependencies.

That is, if item A depends on B and C then the C<depends> method would
return a reference to an array with B and C. ( C<[ 'B', 'C' ]> )

If multiple item names are provided, the same applies. The list returned
will not contain duplicates.

The method returns a reference to an array of item names on success, a
reference to an empty array if no other items are needed, or C<undef>
on error.

NOTE: The result of C<depends> is ordered by an internal C<sort>
irrespective of the ordering provided by the dependency handler.  Use
L<Algorithm::Dependency::Ordered> and C<schedule> to use the most
common ordering (process sequence)

=head2 schedule $name1, ..., $nameN

Given a list of one or more item names, the C<depends> method will
return, as a reference to an array, the ordered list of items you
should act upon in whichever order this particular dependency handler
uses - see L<Algorithm::Dependency::Ordered> for one that implements
the most common ordering (process sequence).

This would be the original names provided, plus those added to satisfy
dependencies, in the preferred order of action. For the normal algorithm,
where order it not important, this is alphabetical order. This makes it
easier for someone watching a program operate on the items to determine
how far you are through the task and makes any logs easier to read.

If any of the names you provided in the arguments is already selected, it
will not be included in the list.

The method returns a reference to an array of item names on success, a
reference to an empty array if no items need to be acted upon, or C<undef>
on error.

=head2 schedule_all;

The C<schedule_all> method acts the same as the C<schedule> method, but 
returns a schedule that selected all the so-far unselected items.

=head1 TO DO

Add the C<check_source> method, to verify the integrity of the source.

Possibly add Algorithm::Dependency::Versions, to implement an ordered
dependency tree with versions, like for perl modules.

Currently readonly. Make the whole thing writable, so the module can be
used as the core of an actual dependency application, as opposed to just
being a tool.

=head1 SEE ALSO

L<Algorithm::Dependency::Ordered>, L<Algorithm::Dependency::Item>,
L<Algorithm::Dependency::Source>, L<Algorithm::Dependency::Source::File>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Dependency>
(or L<bug-Algorithm-Dependency@rt.cpan.org|mailto:bug-Algorithm-Dependency@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Adam Kennedy Karen Etheridge Mark Murawski

=over 4

=item *

Adam Kennedy <adam@ali.as>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mark Murawski <markm@intellasoft.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
