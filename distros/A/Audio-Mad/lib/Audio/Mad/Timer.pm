package Audio::Mad::Timer;
1;
__END__

=head1 NAME

  Audio::Mad::Timer - Interface to mad_timer_t structure
  
=head1 SYPNOSIS

  my $timer = new Audio::Mad::Timer(15, 505, MAD_UNITS_MILLISECONDS);
  
  my $timer2 = $timer->new_copy();
  $timer2->set(31, 5, MAD_UNITS_CENTISECONDS);
  
  $timer->reset();
  $timer->negate();
  
  if ($timer->compare($timer2) == -1) { print "timer < timer2" }
  
  if ($timer2->sign() == -1) { 
  	print "timer2 is < 0";
  	$timer2->abs();
  	print "timer2 is > 0";
  }
  
  $timer->add($timer2);
  $timer2->multiply(15);
  
  my $ms = $timer2->count(MAD_UNITS_MILLISECONDS);
  my $cs = $timer->fraction(MAD_UNITS_CENTISECONDS);
  
=head1 DESCRIPTION

  This package provides access to the underlying mad_timer_t data
  structure used in the decoder library.  It also provides several
  overloaded methods so you can treat the timer more like a
  fundamental data type than an object.
  
=head1 METHODS

=over 4

=item * new([seconds, fraction, denominator])

  Creates a new timer,  and optionally initializes it's 
  initial count with it's paramaters.  seconds is the whole 
  seconds to add to the timer,  fraction is the whole number of 
  fractional seconds to add to the timer,  denominator is used 
  to divide the fractional seconds before it's added to the timer.
  
=item * new_copy

  Creates a new timer,  and sets the initial value to the
  value of the object it was called on.
  
=item * set(seconds, fraction, denominator])

  Sets the value of the timer,  see the ->new method,  above.
  
=item * reset

  Resets the value of the timer to zero.
  
=item * negate

  Negates the current value of the timer,  in place.
  
=item * compare(timer)

  Returns -1, 0, or 1 if the value of the object is currently
  less than,  equal to,  or greater than (respectively) the
  value of timer.
  
=item * sign

  Returns -1, 0, or 1 if the value of the object is currently
  less than,  equal to,  or greater than (respectively) zero.
  
=item * abs

  Resets the timer to the abosolute value of itself,  in place.
  
=item * add(timer)

  Adds the value of timer to the value of the object.
  
=item * multiply(int)

  Multiplies the value of the object by int.
  
=item * count(units)

  Returns the current count of the timer,  in units,
  generally expressed as a MAD_UNITS constant.
  
=item * fraction(denominator)

  Returns the current whole number of fractional seconds
  in terms of the denominator.
  
=item * +, ++, -, --, *, /

  The set of mathemetical operators that work on Audio::Mad::Timer
  objects.  You may sepecify either another Audio::Mad::Timer
  object or a whole number on the right hand side.
  
=item * >, >=, <, <=, ==, !=, <=>

  The set of comparison operators that work on Audio::Mad::Timer
  objects.
  
=item * ", 0+, ${}, @{}, %{}

  The set of conversion operators that work on Audio::Mad::Timer
  objects.  

=back

=head1 AUTHOR

  Mark McConnell <mischke@cpan.org>
  
=cut
  
  