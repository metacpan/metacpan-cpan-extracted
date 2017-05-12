package Data::Validate;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
use AutoLoader 'AUTOLOAD';

use POSIX;
use Scalar::Util qw(looks_like_number);
use Math::BigInt;
use Config;

@ISA = qw(Exporter);



# no functions are exported by default.  See EXPORT_OK
@EXPORT = qw();

@EXPORT_OK = qw(
		is_integer
		is_numeric
		is_hex
		is_oct
		is_between
		is_greater_than
		is_less_than
		is_equal_to
		is_even
		is_odd
		is_alphanumeric
		is_printable
		length_is_between
);

%EXPORT_TAGS = (
		math	=>	[qw(is_integer is_numeric is_hex is_oct is_between is_greater_than is_less_than is_equal_to is_even is_odd)],
		string	=>	[qw(is_equal_to is_alphanumeric is_printable length_is_between)],
);

$VERSION = '0.09';


# No preloads

1;
__END__

=head1 NAME

Data::Validate - common data validation methods

=head1 SYNOPSIS

  use Data::Validate qw(:math);
  
  if(defined(is_integer($suspect))){
  	print "Looks like an integer\n";
  }
  
  my $name = is_alphanumeric($suspect);
  if(defined($name)){
  	print "$name is alphanumeric, and has been untainted\n";
  } else {
  	print "$suspect was not alphanumeric"
  }
  
  # or as an object
  my $v = Data::Validate->new();
  
  die "'foo' is not an integer" unless defined($v->is_integer('foo'));

=head1 DESCRIPTION

This module collects common validation routines to make input validation,
and untainting easier and more readable.  Most of the functions are not much
shorter than their direct perl equivalent (and are much longer in some cases),
but their names make it clear what you're trying to test for.

Almost all functions return an untainted value if the test passes, and undef if
it fails.  This means that you should always check for a defined status explicitly.
Don't assume the return will be true. (e.g. is_integer(0))

The value to test is always the first (and often only) argument.

=head1 FUNCTIONS

=over 4

=cut

# -------------------------------------------------------------------------------

=pod

=item B<new> - constructor for OO usage

  new();

=over 4

=item I<Description>

Returns a Data::Validator object.  This lets you access all the validator function
calls as methods without importing them into your namespace or using the clumsy
Data::Validate::function_name() format.

=item I<Arguments>

None

=item I<Returns>

Returns a Data::Validate object

=back

=cut

sub new{
	my $class = shift;
	
	return bless {}, $class;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_integer> - is the value an integer?

  is_integer($value);

=over 4

=item I<Description>

Returns the untainted number if the test value is an integer, or can be cast to
one without a loss of precision.  (i.e. 1.0 is considered an integer, but 1.0001 is not.)

=item I<Arguments>

=over 4

=item $value

The potential integer to test.

=back

=item I<Returns>

Returns the untainted integer on success, undef on failure.  Note that the return
can be 0, so always check with defined()

=item I<Notes, Exceptions, & Bugs>

Number translation is done by POSIX casting tools (strtol).

=back

=cut

sub is_integer{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return unless defined($value);
	return unless defined(is_numeric($value)); # for efficiency
	
	# see if we can parse it to an number without loss
	my($int, $leftover) = POSIX::strtod($value);
	
	return if $leftover;
	
	# we're having issues testing very large integers.  Math::BigInt
	# can do this for us, but defeats the purpose of being
	# lightweight. So, we're going to try a huristic method to choose
	# how to test for integernesss
	if(!$Config{uselongdouble} && length($int) > 10){
		my $i = Math::BigInt->new($value);
		return unless $i->is_int();
		
		# untaint
		($int) = $i->bstr() =~ /(.+)/;
		return $int;
	}
		
	 
	# shorter integer must be identical to the raw cast
	return unless (($int + 0) == ($value + 0));
	
	# could still be a float at this point.
	return if $value =~ /[^0-9\-]/;
	
	# looks like it really is an integer.  Untaint it and return
	($value) = $int =~ /([\d\-]+)/;
	
	return $value + 0;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_numeric> - is the value numeric?

  is_numeric($value);

=over 4

=item I<Description>

Returns the untainted number if the test value is numeric according to
Perl's own internal rules.  (actually a wrapper on Scalar::Util::looks_like_number)

=item I<Arguments>

=over 4

=item $value

The potential number to test.

=back

=item I<Returns>

Returns the untainted number on success, undef on failure.  Note that the return
can be 0, so always check with defined()

=item I<Notes, Exceptions, & Bugs>

Number translation is done by POSIX casting tools (strtol).

=back

=cut

sub is_numeric{
	my $self = shift if ref($_[0]);
	my $value = shift;
	
	return unless defined($value);
	
	return unless looks_like_number($value);
	
	# looks like it really is a number.  Untaint it and return
	($value) = $value =~ /([\d\.\-+e]+)/;
	
	return $value  + 0;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_hex> - is the value a hex number?

  is_hex($value);

=over 4

=item I<Description>

Returns the untainted number if the test value is a hex number.

=item I<Arguments>

=over 4

=item $value

The potential number to test.

=back

=item I<Returns>

Returns the untainted number on success, undef on failure.  Note that the return
can be 0, so always check with defined()

=item I<Notes, Exceptions, & Bugs>

None

=back

=cut

sub is_hex {
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return unless defined $value;
	
	return if $value =~ /[^0-9a-f]/i;
	$value = lc($value);
	
	my $int = hex($value);
	return unless (defined $int);
	my $hex = sprintf "%x", $int;
	return $hex if ($hex eq $value);
	
	# handle zero stripping
	if (my ($z) = $value =~ /^(0+)/) {
		return "$z$hex" if ("$z$hex" eq $value);
	}
	
	return;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_oct> - is the value an octal number?

  is_oct($value);

=over 4

=item I<Description>

Returns the untainted number if the test value is a octal number.

=item I<Arguments>

=over 4

=item $value

The potential number to test.

=back

=item I<Returns>

Returns the untainted number on success, undef on failure.  Note that the return
can be 0, so always check with defined()

=item I<Notes, Exceptions, & Bugs>

None

=back

=cut

sub is_oct {
	my $self = shift if ref($_[0]);
	my $value = shift;
	
	return unless defined $value;
	
	return if $value =~ /[^0-7]/;
		
	my $int = oct($value);
	return unless (defined $int);
	my $oct = sprintf "%o", $int;
	return $oct if ($oct eq $value);
	
	# handle zero stripping
	if (my ($z) = $value =~ /^(0+)/) {
		return "$z$oct" if ("$z$oct" eq $value);
	}
	
	return;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_between> - is the value between two numbers?

  is_between($value, $min, $max);

=over 4

=item I<Description>

Returns the untainted number if the test value is numeric, and falls between
$min and $max inclusive.  Note that either $min or $max can be undef, which 
means 'unlimited'.  i.e. is_between($val, 0, undef) would pass for any number
zero or larger.

=item I<Arguments>

=over 4

=item $value

The potential number to test.

=item $min

The minimum valid value.  Unlimited if set to undef

=item $max

The maximum valid value.  Unlimited if set to undef

=back

=item I<Returns>

Returns the untainted number on success, undef on failure.  Note that the return
can be 0, so always check with defined()


=back

=cut

sub is_between{
	my $self = shift if ref($_[0]);
	my $value = shift;
	my $min = shift;
	my $max = shift;
	
	# must be a number
	my $untainted = is_numeric($value);
	return unless defined($untainted);
	
	# issues with very large numbers.  Fall over to using 
	# arbitrary precisions math.
	if(length($value) > 10){
		
		my $i = Math::BigInt->new($value);
		
		# minimum bound
		if(defined($min)){
			$min = Math::BigInt->new($min);
			return unless $i >= $min;
		}
		
		# maximum bound
		if(defined($max)){
			$max = Math::BigInt->new($max);
			return unless $i <= $max;
		}
		
		# untaint
		($value) = $i->bstr() =~ /(.+)/;
		return $value;
	}
	
	
	# minimum bound
	if(defined($min)){
		return unless $value >= $min;
	}
	
	# maximum bound
	if(defined($max)){
		return unless $value <= $max;
	}
	
	return $untainted;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_greater_than> - is the value greater than a threshold?

  is_greater_than($value, $threshold);

=over 4

=item I<Description>

Returns the untainted number if the test value is numeric, and is greater than
$threshold. (not inclusive)

=item I<Arguments>

=over 4

=item $value

The potential number to test.

=item $threshold

The minimum value (non-inclusive)

=back

=item I<Returns>

Returns the untainted number on success, undef on failure.  Note that the return
can be 0, so always check with defined()


=back

=cut

sub is_greater_than{
	my $self = shift if ref($_[0]);
	my $value = shift;
	my $threshold = shift;
		
	# must be a number
	my $untainted = is_numeric($value);
	return unless defined($untainted);
	
	# threshold must be defined
	return unless defined $threshold;
	
	return unless $value > $threshold;
		
	return $untainted;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_less_than> - is the value less than a threshold?

  is_less_than($value, $threshold);

=over 4

=item I<Description>

Returns the untainted number if the test value is numeric, and is less than
$threshold. (not inclusive)

=item I<Arguments>

=over 4

=item $value

The potential number to test.

=item $threshold

The maximum value (non-inclusive)

=back

=item I<Returns>

Returns the untainted number on success, undef on failure.  Note that the return
can be 0, so always check with defined()


=back

=cut

sub is_less_than{	
	my $self = shift if ref($_[0]);
	my $value = shift;
	my $threshold = shift;
		
	# must be a number
	my $untainted = is_numeric($value);
	return unless defined($untainted);
	
	# threshold must be defined
	return unless defined $threshold;
	
	return unless $value < $threshold;
		
	return $untainted;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_equal_to> - do a string/number neutral ==

  is_equal_to($value, $target);

=over 4

=item I<Description>

Returns the target if $value is equal to it.  Does a math comparison if
both $value and $target are numeric, or a string comparison otherwise. 
Both the $value and $target must be defined to get a true return.  (i.e.
undef != undef)

=item I<Arguments>

=over 4

=item $value

The  value to test.

=item $target

The value to test against

=back

=item I<Returns>

Unlike most validator routines, this one does not necessarily untaint its return value,
it just returns $target.  This has the effect of untainting if the target is a constant or
other clean value.  (i.e. is_equal_to($bar, 'foo')).  Note that the return
can be 0, so always check with defined()


=back

=cut

sub is_equal_to{
	my $self = shift if ref($_[0]);
	my $value = shift;
	my $target = shift;
	
	# value and target must be defined
	return unless defined $value;
	return unless defined $target;
	
	if(defined(is_numeric($value)) && defined(is_numeric($target))){
		return $target if $value == $target;
	} else {
		# string comparison
		return $target if $value eq $target;
	}
	
	return;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_even> - is a number even?

  is_even($value);

=over 4

=item I<Description>

Returns the untainted $value if it's numeric, an integer, and even.

=item I<Arguments>

=over 4

=item $value

The  value to test.

=back

=item I<Returns>

Returns $value (untainted). Note that the return can be 0, so always
check with defined().


=back

=cut

sub is_even{
	my $self = shift if ref($_[0]);
	my $value = shift;
	
	return unless defined(is_numeric($value));
	my $untainted = is_integer($value);
	return unless defined($untainted);
	
	return $untainted unless $value % 2;
	
	return;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_odd> - is a number odd?

  is_odd($value);

=over 4

=item I<Description>

Returns the untainted $value if it's numeric, an integer, and odd.

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Returns $value (untainted). Note that the return can be 0, so always
check with defined().

=back

=cut

sub is_odd{
	my $self = shift if ref($_[0]);
	my $value = shift;
	
	return unless defined(is_numeric($value));
	my $untainted = is_integer($value);
	return unless defined($untainted);
	
	return $untainted if $value % 2;
	
	return;
}



# -------------------------------------------------------------------------------

=pod

=item B<is_alphanumeric> - does it only contain letters and numbers?

  is_alphanumeric($value);

=over 4

=item I<Description>

Returns the untainted $value if it is defined and only contains letters (upper
or lower case) and numbers.  Also allows an empty string - ''.

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Returns $value (untainted). Note that the return can be 0, so always
check with defined().

=back

=cut

sub is_alphanumeric{
	my $self = shift if ref($_[0]);
	my $value = shift;
	
	return unless defined($value);
	return '' if $value eq ''; # allow for empty string
	
	my($untainted) = $value =~ /([a-z0-9]+)/i;
	
	return unless defined($untainted);
	return unless $untainted eq $value;
	
	return $untainted;
	
}


# -------------------------------------------------------------------------------

=pod

=item B<is_printable> - does it only contain printable characters?

  is_alphanumeric($value);

=over 4

=item I<Description>

Returns the untainted $value if it is defined and only contains printable characters
as defined by the composite POSIX character class [[:print:][:space:]].  Also allows an empty string - ''.

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Returns $value (untainted). Note that the return can be 0, so always
check with defined().

=back

=cut

sub is_printable{
	my $self = shift if ref($_[0]);
	my $value = shift;
	
	return unless defined($value);
	return '' if $value eq ''; # allow for empty string
	
	my($untainted) = $value =~ /([[:print:][:space:]]+)/i;
	
	return unless defined($untainted);
	return unless $untainted eq $value;

	return $untainted;
	
}


# -------------------------------------------------------------------------------

=pod

=item B<length_is_between> - is the string length between two limits?

  length_is_between($value, $min, $max);

=over 4

=item I<Description>

Returns $value if it is defined and its length
is between $min and $max inclusive.  Note that this function does not
untaint the value.

If either $min or $max are undefined they are treated as no-limit.

=item I<Arguments>

=over 4

=item $value

The value to test.

=item $min

The minimum length of the string (inclusive).

=item $max

The maximum length of the string (inclusive).

=back

=item I<Returns>

Returns $value.  Note that the return can be 0, so always check with
defined().  The value is not automatically untainted.

=back

=cut

sub length_is_between{
	my $self = shift if ref($_[0]);
	my $value = shift;
	my $min = shift;
	my $max = shift;
	
	return unless defined($value);
	
	if(defined($min)){
		return unless length($value) >= $min;
	}
	
	if(defined($max)){
		return unless length($value) <= $max;
	}
	
	return $value;
	
}


=pod

=back

=head1 AUTHOR

Richard Sonnen <F<sonnen@richardsonnen.com>>.

=head1 COPYRIGHT

Copyright (c) 2004 Richard Sonnen. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
