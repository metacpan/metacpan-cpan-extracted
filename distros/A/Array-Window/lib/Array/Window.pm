package Array::Window;

use 5.005;
use strict;
use Params::Util '_ARRAYLIKE';

use vars qw{$VERSION};
BEGIN { 
	$VERSION = '1.02';
}

# A description of the properties
# 
# source_start          - The lowest index of the source array
# source_end            - The highest index of the source array
# source_length         - The total length of the source
# window_start          - The lowest index of the data window
# window_end            - The highest index of the data window
# window_length         - The length of the window ( number of items inclusive )
# window_length_desired - The length of the window they would LIKE to have
# previous_start        - The index number of window_start for the "Previous" window
# next_start            - The index number of window_start for the "Next" window

sub new {
	my $class   = shift;
	my %options = @_;

	# Create the new object
	my $self = bless {
		source_start          => undef,
		source_end            => undef,
		source_length         => undef,
		window_start          => undef,
		window_end            => undef,
		window_length         => undef,
		window_length_desired => undef,
		previous_start        => undef,
		next_start            => undef,
		}, $class;

	# Check for a specific source
	if ( $options{source} ) {
		_ARRAYLIKE($options{source}) or return undef;
		$self->{source_start}  = 0;
		$self->{source_end}    = $#{$options{source}};
		$self->{source_length} = $self->{source_end} + 1;

	} elsif ( defined $options{source_start} and defined $options{source_end} ) {
		$self->{source_start}  = $options{source_start};
		$self->{source_end}    = $options{source_end};
		$self->{source_length} = $options{source_end} - $options{source_start} + 1;

	} elsif ( defined $options{source_start} and defined $options{source_length} ) {
		return undef unless $options{source_length} > 0;
		$self->{source_start}  = $options{source_start};
		$self->{source_end}    = $options{source_start} + $options{source_length} - 1;
		$self->{source_length} = $options{source_length};

	} elsif ( defined $options{source_end} and defined $options{source_length} ) {
		return undef unless $options{source_length} > 0;
		$self->{source_start}  = $options{source_end} - $options{source_length} + 1;
		$self->{source_end}    = $options{source_end};
		$self->{source_length} = $options{source_length};

	} elsif ( defined $options{source_length} ) {
		return undef unless $options{source_length} > 0;
		$self->{source_start}  = 0;
		$self->{source_end}    = $options{source_length} - 1;
		$self->{source_length} = $options{source_length};

	} else {
		# Source not defined
		return undef;
	}

	# Do we have the window start?
	if ( defined $options{window_start} ) {
		# We can't be before the beginning
		$self->{window_start} = $options{window_start};
	} else {
		return undef;
	}

	# Do we have the window length?
	if ( defined $options{window_length} ) {
		return undef unless $options{window_length} > 0;
		$self->{window_length} = $options{window_length};
		$self->{window_length_desired} = $options{window_length};
	} elsif ( defined $options{window_end} ) {
		return undef if $options{window_end} < $self->{window_start};
		$self->{window_end} = $options{window_end};
	} else {
		# Not enough data to do the math
		return undef;
	}

	# Do the math
	$self->_calculate;

	return $self;
}

# Do the calculations to set things as required.
# We also support incremental calculations.
sub _calculate {
	my $self = shift;

	# First, finish the third of the window_ values.
	# This will be either window_length or window_end.
	$self->_calculate_window_end    unless defined $self->{window_end};
	$self->_calculate_window_length unless defined $self->{window_length};

	# Adjust the window back into the source if needed
	if ( $self->{window_start} < $self->{source_start} ) {
		$self->{window_start} += ($self->{source_start} - $self->{window_start});
		$self->_calculate_window_end;

		# If this move puts window_end after source_end, fix it
		if ( $self->{window_end} > $self->{source_end} ) { 
			$self->{window_end} = $self->{source_end};
			$self->_calculate_window_length;
		}
	}
	if ( $self->{window_end} > $self->{source_end} ) {
		$self->{window_start} -= ($self->{window_end} - $self->{source_end});
		$self->_calculate_window_end;

		# If this move puts window_start before source_start, fix it
		if ( $self->{window_start} < $self->{source_start} ) {
			$self->{window_start} = $self->{source_start};
			$self->_calculate_window_length;
		}
	}

	# Calculate the next window_start
	if ( $self->{window_end} == $self->{source_end} ) {
		$self->{next_start} = undef;
	} else {
		$self->{next_start} = $self->{window_end} + 1;
	}

	# Calculate the previous window_start
	if ( $self->{window_start} == $self->{source_start} ) {
		$self->{previous_start} = undef;
	} else {
		$self->{previous_start} = $self->{window_start} - $self->{window_length};
		if ( $self->{previous_start} < $self->{source_start} ) {
			$self->{previous_start} = $self->{source_start};
		}
	}

	return 1;
}

# Smaller calculation componants
sub _calculate_window_start {
	my $self = shift;
	$self->{window_start} = $self->{window_end} - $self->{window_length} + 1;
}
sub _calculate_window_end {
	my $self = shift;
	$self->{window_end} = $self->{window_start} + $self->{window_length} - 1;
}
sub _calculate_window_length {
	my $self = shift;
	$self->{window_length} = $self->{window_end} - $self->{window_start} + 1;
}





#####################################################################
# Access methods

sub source_start          { $_[0]->{source_start}          }
sub source_end            { $_[0]->{source_end}            }
sub human_source_start    { $_[0]->{source_start} + 1      }
sub human_source_end      { $_[0]->{source_end} + 1        }
sub source_length         { $_[0]->{source_length}         }
sub window_start          { $_[0]->{window_start}          }
sub window_end            { $_[0]->{window_end}            }
sub human_window_start    { $_[0]->{window_start} + 1      }
sub human_window_end      { $_[0]->{window_end} + 1        }
sub window_length         { $_[0]->{window_length}         }
sub window_length_desired { $_[0]->{window_length_desired} }
sub previous_start        { $_[0]->{previous_start}        }
sub next_start            { $_[0]->{next_start}            }

# Get an object representing the first window.
# Returns 0 if we are currently the first window
sub first {
	my $self  = shift;
	my $class = ref $self;

	# If the window_start is equal to the source_start, return false
	return '' if $self->{source_start} == $self->{window_start};

	# Create the first window
	return $class->new(
		source_start  => $self->{source_start},
		source_end    => $self->{source_end},
		window_length => $self->{window_length_desired},
		window_start  => $self->{source_start},
	);
}

# Get an object representing the last window.
# Returns false if we are already the last window.
sub last {
	my $self  = shift;
	my $class = ref $self;

	# If the window_end is equal to the source_end, return false
	return '' if $self->{source_end} == $self->{window_end};

	# Create the last window
	my $window_start = $self->{source_end} - $self->{window_length_desired} + 1;
	return $class->new(
		source_start  => $self->{source_start},
		source_end    => $self->{source_end},
		window_start  => $window_start,
		window_end    => $self->{source_end},
	);
}

# Get an object representing the next window.
# Returns 0 if there is no next window.
sub next {
	my $self  = shift;
	my $class = ref $self;

	# If there is no next, return false
	return '' unless defined $self->{next_start};

	# Create the next window	
	return $class->new( 
		source_start  => $self->{source_start},
		source_end    => $self->{source_end},
		window_length => $self->{window_length_desired},
		window_start  => $self->{next_start},
	);
}

sub previous {
	my $self  = shift;
	my $class = ref $self;

	# If there is no previou, return false
	return '' unless defined $self->{previous_start};

	# Create the previous window
	return $class->new(
		source_start  => $self->{source_start},
		source_end    => $self->{source_end},
		window_length => $self->{window_length_desired},
		window_start  => $self->{previous_start},
	);
}

# Method to determine if we need to do windowing.
# The method returns false if the subset is the entire set, 
# and true if the subset is smaller than the set
sub required {
	my $self = shift;
	return 1 unless $self->{source_start} == $self->{window_start};
	return 1 unless $self->{source_end}   == $self->{window_end};
	return '';
}

# $window->extract( \@array );
# Method takes a set that matches the window parameters, and extracts
# the specified window
# Returns a reference to the sub array on success
# Returns undef if the array does not match the window
sub extract {
	my $self = shift;
	my $arrayref = shift;

	# Check that they match
	return undef unless $self->{source_start} == 0;
	return undef unless $self->{source_end}   == $#$arrayref;

	# Create the sub array
	my @subarray = ();
	@subarray = @{$arrayref}[$self->window_start .. $self->window_end];

	# Return a reference to the sub array
	return \@subarray;
}
	
1;

__END__

=pod

=head1 NAME

Array::Window - Calculate windows/subsets/pages of arrays.

=head1 SYNOPSIS

  # Your search routine returns an reference to an array
  # of sorted results of unknown quantity.
  my $results = SomeSearch->find( 'blah' );
  
  # We want to display 20 results at a time
  my $window = Array::Window->new( 
  	source        => $results,
  	window_start  => 0,
  	window_length => 20,
  	);
  
  # Do we need to split into pages at all?
  my $show_pages = $window->required;
  
  # Extract the subset from the array
  my $subset = $window->extract( $results );
  
  # Are there 'first', 'last', 'next' or 'previous' windows?
  my $first    = $window->first;
  my $last     = $window->last;
  my $next     = $window->next;
  my $previous = $window->previous;

=head1 DESCRIPTION

Many applications require that a large set of results be broken down
into a smaller set of 'windows', or 'pages' in web language. Array::Window
implements an algorithm specifically for dealing with these windows. It
is very flexible and permissive, making adjustments to the window as needed.

Note that this is NOT under Math:: for a reason. It doesn't implement
in a pure fashion, it handles idiosyncracies and corner cases specifically
relating to the presentation of data.

=head2 Values are not in human terms

People will generally refer to the first value in a set as the 1st element,
that is, a set containing 10 things will start at 1 and go up to 10.
Computers refer to the first value as the '0th' element, with the same set
starting at 0 and going up to 9.

The normal methods for this class return computer orientated values. If you
want to generate values for human messages, you should instead use the following.

  print 'Displaying Widgets ' . $window->human_window_start
  	. ' to ' . $window->human_window_end
  	. ' of ' . $window->human_source_end;

=head1 METHODS

=head2 new %options

The C<new> constructor is very flexible with regards to the options that can
be passed to it. However, this generally breaks down into deriving two things.

Firstly, it needs know about the source, usually an array, but more 
generically handled as a range of integers. This means that although the 
"first" element of the array would typically be zero, C<Array::Window> can
handle ranges where the first element is something other than zero.

For a typical 100 element array C<@array>, you could use any of the following
sets of options for defining the source array.

  Array::Window->new( source => \@array );
  Array::Window->new( source_length => 100 ); # Assume start at zero
  Array::Window->new( source_start => 0, source_end => 99  );
  Array::Window->new( source_start => 0, source_length => 100 );
  Array::Window->new( source_end => 99,  source_length => 100 );

Secondly, the object needs to know information about Window it will be 
finding. Assuming a B<desired> window size of 10, and assuming we use the first
of the two options above, you would end up with the following.

  # EITHER
  Array::Window->new( source => \@array, 
  	window_start => 0, window_length => 10 );
  
  # OR
  Array::Window->new( source => \@array,
  	window_start => 0, window_end => 9 );

Although the second option looks a little silly, bear in mind that Array::Window
will not assume that just because you WANT a window from 0 - 9, it's actually 
going to fit the size of the array.

Please note that the object does NOT make a copy or otherwise retain information
about the array, so if you change the array later, you will need to create a new
object.

=head2 source_start

Returns the index of the first source value, which will usually be 0.

=head2 source_end

Returns the index of the last source value, which for array C<@array>, will be
the same as C<$#array>.

=head2 source_length

Returns the number of elements in the source array.

=head2 window_start

Returns the index of the first value in the window.

=head2 window_end

Returns the index of the last value in the window.

=head2 window_length

Returns the length of the window. This is NOT guarenteed to be the same as 
you initially entered, as the value you entered may have not fit. Imagine
trying to get a 100 element long window on a 10 element array. Something
has to give.

=head2 window_length_desired

Returns the desired window length. i.e. The value you originally entered.

=head2 human_window_start

Returns the index of the first value in the window in human terms ( 1 .. n )

=head2 human_window_end

Returns the index of the last value in the window in human terms ( 1 .. n )

=head2 previous_start

If a 'previous' window can be calculated, this will return the index of the
start of the previous window.

=head2 next_start

If a 'next' window can be calculated, this will return the index of the start
of the next window.

=head2 first

This method returns an C<Array::Window> object representing the first window,
which you can then use as needed. Returns false if the current window is
already the first window.

=head2 last

This method return an C<Array::Window> object representing the last window,
which you can then use as needed. Returns false if the current window is
already the last window.

=head2 previous

This method returns an C<Array::Window> object representing the previous 
window, which you can then apply as needed. Returns false if the window is
already at the 'beginning' of the source, and no previous window exists.

=head2 next

This method returns an C<Array::Window> object representing the next window,
which you can apply as needed. Returns false if the window is already at the
'end' of the source, and no window exists after this one.

=head2 required

Looks at the window and source and tries to determine if the entire source
can be shown without the need for windowing. This can be usefull for interface
code, as you can avoid generating 'next' or 'previous' controls at all.

=head2 extract \@array

Applies the object to an array, extracting the subset of the array that the
window represents.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Window>

For other issues, or commercial enhancement or support, contact the author.

=head1 TO DO

- Determine how many windows there are.

- Provide the option to only work at strict intervals

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Set::Window>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2002 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
