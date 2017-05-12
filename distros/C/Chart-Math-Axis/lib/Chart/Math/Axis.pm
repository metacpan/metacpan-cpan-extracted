package Chart::Math::Axis;

# This is a package implements an algorithm for calculating
# a good vertical scale for a graph.
# That is, given a data set, find a maximum, minimum and interval values
# that will provide the most attractive display for a graph.

use 5.005;
use strict;
use Storable       2.12 ();
use Math::BigInt   1.70 ();
use Math::BigFloat 1.44 (); # Needs bdiv
use Params::Util   0.15 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.06';
}





###############################################################################
# Public Methods

# Constructor is passed a list of values, which should be the entire set of
# values on the Y axis.
sub new {
	# Create the object
	my $self = bless {
		max               => undef, # Data maximum value
		min               => undef, # Data minimum value
		top               => undef, # Top value on the axis
		bottom            => undef, # Bottom value on the axis
		maximum_intervals => 10,    # Maximum number of intervals
		interval_size     => undef, # The interval size		
	}, shift;

	# If we got some argument
	if ( @_ ) {
		# Add the data from the data set.
		# ->_add_data will trigger the calculation process.
		$self->add_data( @_ ) or return undef;
	}

	$self;
}

# Data access methods
sub max               { $_[0]->{max}               }
sub min               { $_[0]->{min}               }
sub top               { $_[0]->{top}               }
sub bottom            { $_[0]->{bottom}            }
sub maximum_intervals { $_[0]->{maximum_intervals} }
sub interval_size     { $_[0]->{interval_size}     }

# Return the actual number of ticks that should be needed
sub ticks {
	my $self = shift;
	return undef unless defined $self->{max};
	return undef unless defined $self->{min};
	return undef unless defined $self->{interval_size};

	# Calculate the ticks
	return ($self->{top} - $self->{bottom}) / $self->{interval_size};
}

# Method to force the scale to include the zero line.
sub include_zero {
	$_[0]->add_data(0);
}

# Method to add additional data elements to the data set
# The object doesn't need to store all the data elements, 
# just the maximum and minimum values
sub add_data {
	my $self = shift;

	# Make sure they passed at least one data element
	return undef unless @_;

	# Handle the case of when this is the first data
	$self->{max} = $_[0] unless defined $self->{max};
	$self->{min} = $_[0] unless defined $self->{min};

	# Go through and adjust the max and min as needed
	foreach ( @_ ) {
		$self->{max} = $_ if $_ > $self->{max};
		$self->{min} = $_ if $_ < $self->{min};
	}

	# Recalculate
	$self->_calculate;
}

# Change the interval quantity.
# Change this to stupid values, and I can't guarantee this module won't break.
# It needs to be robuster ( is that a word? )
# You will not get the exact number of intervals you specify.
# You are only guaranteed not to get MORE than this.
# The point being that if your labels take up X width, you
# can specify a maximum number of ticks not to exceed.
sub set_maximum_intervals {
	my $self     = shift;
	my $quantity = $_[0] > 1 ? shift : return undef;

	# Set the interval quantity
	$self->{maximum_intervals} = $quantity;

	# Recalculate
	$self->_calculate;
}

# Automatically apply the axis values to objects of different types.
# Currently only GD::Graph objects are supported.
sub apply_to {
	my $self = shift;
	unless ( Params::Util::_INSTANCE($_[0], 'GD::Graph::axestype') ) {
		die "Tried to apply scale to an unknown graph type";
	}

	shift->set( 
		y_max_value   => $self->top,
		y_min_value   => $self->bottom,
		y_tick_number => $self->ticks,
	);

	1;
}





###############################################################################
# Private methods

# This method implements the main part of the algorithm
sub _calculate {
	my $self = shift;

	# Max sure we have a maximum, minimum, and interval quantity
	return undef unless defined $self->{max};
	return undef unless defined $self->{min};
	return undef unless defined $self->{maximum_intervals};

	# Pass off the special max == min case to the dedicated method
	return $self->_calculate_single if $self->{max} == $self->{min};

	# Get some math objects for the max and min
	my $Maximum = Math::BigFloat->new( $self->{max} );
	my $Minimum = Math::BigFloat->new( $self->{min} );
	return undef unless (defined $Maximum or defined $Minimum);

	# Get the magnitude of the numbers
	my $max_magnitude = $self->_order_of_magnitude( $Maximum );
	my $min_magnitude = $self->_order_of_magnitude( $Minimum );

	# Find the largest order of magnitude
	my $magnitude = $max_magnitude > $min_magnitude
		? $max_magnitude : $min_magnitude;

	# Create some starting values based on this
	my $Interval           = Math::BigFloat->new( 10 ** ($magnitude + 1) );
	my $Top                = $self->_round_top( $Maximum, $Interval );
	my $Bottom             = $self->_round_bottom( $Minimum, $Interval );
	$self->{top}           = $Top->bstr;
	$self->{bottom}        = $Bottom->bstr;
	$self->{interval_size} = $Interval->bstr;

	# Loop as we tighten the integer until the correct number of
	# intervals are found.
	my $loop = 0;
	while ( 1 ) {
		# Descend to the next interval
		my $NextInterval = $self->_reduce_interval( $Interval ) or return undef;

		# Get the rounded values for the maximum and minimum
		$Top = $self->_round_top( $Maximum, $NextInterval );
		$Bottom = $self->_round_bottom( $Minimum, $NextInterval );

		# How many intervals fit into this range?
		my $NextIntervalQuantity = ( $Top - $Bottom ) / $NextInterval;

		# If the number of intervals for the next interval is higher
		# then the maximum number of allowed intervals, use the 
		# current interval
		if ( $NextIntervalQuantity > $self->{maximum_intervals} ) {
			# Finished, return.
			return 1;
		}

		# Set the Interval to the next interval
		$Interval              = $NextInterval;
		$self->{top}           = $Top->bstr;
		$self->{bottom}        = $Bottom->bstr;
		$self->{interval_size} = $Interval->bstr;

		# Infinite loop protection
		return undef if ++$loop > 100;
	}
}

# Handle special calculation case of max == min
sub _calculate_single {
	my $self = shift;

	# Max sure we have a maximum, minimum, and interval quantity
	return undef unless defined $self->{max};
	return undef unless defined $self->{min};
	return undef unless defined $self->{maximum_intervals};

	# Handle the super special case of one value of zero
	if ( $self->{max} == 0 ) {
		$self->{top}           = 1;
		$self->{bottom}        = 0;
		$self->{interval_size} = 1;
		return 1;
	}

	# When we only have one value ( that's not zero ), we can get
	# a top and bottom by rounding up and down at the value's order of magnitude
	my $Value              = Math::BigFloat->new( $self->{max} );
	my $magnitude          = $self->_order_of_magnitude( $Value );
	my $Interval           = Math::BigFloat->new( 10 ** $magnitude );
	$self->{top}           = $self->_round_top( $Value, $Interval )->bstr;
	$self->{bottom}        = $self->_round_bottom( $Value, $Interval )->bstr;
	$self->{interval_size} = $Interval->bstr;

	# Tighten the same way we do in the normal _calculate method
	# but don't recalculate the top and bottom
	# Loop as we tighten the integer until the correct number of
	# intervals are found. 
	my $loop = 0;
	while ( 1 ) {
		# Descend to the next interval
		my $NextInterval = $self->_reduce_interval( $Interval ) or return undef;
		my $NextIntervalQuantity = ( $self->{top} - $self->{bottom} ) / $NextInterval;

		if ( $NextIntervalQuantity > $self->{maximum_intervals} ) {
			# Finished, return.
			return 1;
		}

		# Set the Interval to the next interval
		$Interval = $NextInterval;
		$self->{interval_size} = $Interval->bstr;

		# Infinite loop protection
		return undef if ++$loop > 100;
	}
}

# For a given interval, work out what the next one down should be
sub _reduce_interval {
	my $class    = shift;
	my $Interval = Params::Util::_INSTANCE($_[0], 'Math::BigFloat')
		? Storable::dclone( shift ) # Don't modify the original
		: Math::BigFloat->new( shift );

	# If the mantissa is 5, reduce it to 2
	if ( $Interval->mantissa == 5 ) {
		return $Interval * (2 / 5);

	# If the mantissa is 2, reduce it to 1
	} elsif ( $Interval->mantissa == 2 ) {
		return $Interval * (1 / 2);

	# If the mantissa is 1, make it 5 and subtract one from the exponent
	} elsif ( $Interval->mantissa == 1 ) {
		return $Interval * (5 / 10);

	} else {
		# We got a problem here.
		# This is not a value we should expect.
		return undef;
	}
}

# Find the order of magnitude for a BigFloat.
# Not the same as exponent.
sub _order_of_magnitude {
	my $class    = shift;
	my $BigFloat = Params::Util::_INSTANCE($_[0], 'Math::BigFloat')
		? Storable::dclone( shift ) # Don't modify the original
		: Math::BigFloat->new( shift );

	# Zero is special, and won't work with the math below
	return 0 if $BigFloat == 0;
	
	# Calculate the ordinality
	my $Ordinality = $BigFloat->mantissa->length
		+ $BigFloat->exponent - 1;
	
	# Return it as a normal perl int
	$Ordinality->bstr;
}

# Two rounding methods to handle the special rounding cases we need
sub _round_top {
	my $class  = shift;
	my $Number = Params::Util::_INSTANCE($_[0], 'Math::BigFloat')
		? Storable::dclone( shift ) # Don't modify the original
		: Math::BigFloat->new( shift );
	my $Interval = shift;

	# Round up, or go one interval higher if exact
	$Number = $Number->bdiv( $Interval ); # Divide
	$Number = $Number->bfloor->binc;      # Round down and add 1
	$Number = $Number * $Interval;        # Re-multiply
}

sub _round_bottom {
	my $class  = shift;
	my $Number = Params::Util::_INSTANCE($_[0], 'Math::BigFloat')
		? Storable::dclone( shift ) # Don't modify the original
		: Math::BigFloat->new( shift );
	my $Interval = shift;

	# In the special case the number is zero, don't round down.
	# If the graph is already anchored to zero at the bottom, we
	# don't want to show down to -1 * $Interval.
	return $Number if $Number == 0;

	# Round down, or go one interval lower if exact.
	$Number = $Number->bdiv( $Interval ); # Divide
	$Number = $Number->bceil->bdec;       # Round up and subtract 1
	$Number = $Number * $Interval;        # Re-multiply
}

1;

__END__

=pod

=head1 NAME

Chart::Math::Axis - Implements an algorithm to find good values for chart axis

=head1 SYNOPSIS

  # Create a new Axis
  my $axis = Chart::Math::Axis->new;
  
  # Provide is some data to calculate on
  $axis->add_data( @dataset );
  
  # Get the values for the axis
  print "Top of axis: "     . $axis->top           . "\n";
  print "Bottom of axis: "  . $axis->bottom        . "\n";
  print "Tick interval: "   . $axis->interval_size . "\n";
  print "Number of ticks: " . $axis->ticks         . "\n";
  
  # Apply the axis directly to a GD::Graph.
  $axis->apply_to( $graph );

=head1 DESCRIPTION

B<Chart::Math::Axis> implements in a generic way an algorithm for finding
a set of ideal values for an axis. That is, for any given set of
data, what should the top and bottom of the axis scale be, and what
should the interval between the ticks be.

The terms C<top> and C<bottom> are used throughout this module, as it's
primary use is for determining the Y axis. For calculating the X axis,
you should think of 'top' as 'right', and 'bottom' as 'left'.

=head1 METHODS

=head2 new

  my $null = Chart::Math::Axis->new;
  my $full = Chart::Math::Axis->new( @dataset );

The C<new> method creates a new C<Chart::Math::Axis> object. Any arguments
passed to the constructor are used as dataset values. Whenever the object
has some values on which to work, it will calculate the axis. If the object
is created with no values, most methods will return undef.

=head2 max

Returns the maximum value in the dataset.

=head2 min

Returns the minimum value in the dataset.

=head2 top

The C<top> method returns the value that should be the top of the axis.

=head2 bottom

The C<bottom> method returns the value that should be the bottom of the axis.

=head2 maximum_intervals

Although Chart::Math::Axis can work out scale and intervals, it doesn't know
how many pixels you might need, how big labels etc are, so it can
determine the tick density you are going to need. The C<maximum_intervals>
method returns the current value for the maximum number of ticks the object
is allowed to have.

To change this value, see the C<set_maximum_intervals> method. The default
for the maximum number of intervals is 10.

=head2 interval_size

The C<interval_size> method returns the interval size in dataset terms.

=head2 ticks

The C<ticks> method returns the number of intervals that the top/bottom/size
values will result in.

=head2 add_data

  $self->add_data( @dataset );

The C<add_data> method allows you to provide data that the object should be
aware of when calculating the axis. In fact, you can add additional data
at any time, and the axis will be updated as needed.

=head2 set_maximum_intervals

  $self->set_maximum_intervals( $intervals );

The C<set_maximum_intervals> method takes an argument and uses it as the
maximum number of ticks the axis is allowed to have.

=head2 include_zero

If you have a dataset something like ( 10, 11, 12 ) the bottom of the axis
will probably be somewhere around 9 or 8. That is, it won't show the zero 
axis. If you want to force the axis to include zero, use this method to do so.

=head2 apply_to

  $self->apply_to( $gd_graph_object )

The C<apply_to> method is intended to provide a series of shortcuts for 
automatically applying an axis to a graph of a know type. At the present,
this will change only the Y axis of a GD::Graph object. This method is 
considered experimental. If in doubt, extract and set the graph values
yourself.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chart-Math-Axis>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<GD::Graph>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2002 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
