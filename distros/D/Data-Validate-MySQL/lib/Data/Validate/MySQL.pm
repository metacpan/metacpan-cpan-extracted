package Data::Validate::MySQL;

use 5.008;
use strict;
use warnings;

require Exporter;
use AutoLoader 'AUTOLOAD';
use Carp;
use Data::Validate 0.06 qw(is_integer is_between is_numeric);
use Math::BigFloat;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( 
	is_bit
	is_tinyint
	is_boolean
	is_smallint
	is_mediumint
	is_int
	is_bigint
	is_float
	is_double
	is_decimal
	is_char
	is_varchar
	is_binary
	is_varbinary
	is_tinyblob
	is_tinytext
	is_blob
	is_text
	is_mediumblob
	is_mediumtext
	is_longblob
	is_longtext
	is_enum
	is_set
	is_date
	is_datetime
	is_timestamp
	is_time
	is_year
);

# no functions are exported by default.  See EXPORT_OK
our @EXPORT = qw();

our $VERSION = '0.03';


# no preloads

1;
__END__

=head1 NAME

Data::Validate::MySQL - validate against MySQL data types

=head1 SYNOPSIS

  use Data::Validate::MySQL qw(is_int);
  
  die "That's not an unsigned integer!" unless defined(is_int($suspect, 1));

  # or as an object
  my $v = Data::Validate::MySQL->new();
  
  die "That's not an unsigned integer!" unless defined($v->is_int($suspect, 1));

=head1 DESCRIPTION

This module collects common validation routines to check suspect values against
MySQL column types.  For example, you can check to make sure your integer values
are within range, your strings aren't too big, and that your dates and times
look vaguely ISO-ish.  Validating your values before trying to insert them
into MySQL is critical, particularly since MySQL is very tolerant of bad data
by default, so you may end up with useless values in your tables even if 
the database doesn't complain.

All functions return an untainted value if the test passes, and undef if
it fails.  This means that you should always check for a defined status explicitly.
Don't assume the return will be true. (e.g. is_integer('0'))

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

Returns a Data::Validator::MySQL object.  This lets you access all the validator function
calls as methods without importing them into your namespace or using the clumsy
Data::Validate::MySQL::function_name() format.

=item I<Arguments>

None

=item I<Returns>

Returns a Data::Validate::MySQL object

=back

=cut

sub new{
	my $class = shift;
	
	return bless {}, $class;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_bit> - is the value a valid bit field?

  is_bit($value, [$size], [$raw]);

=over 4

=item I<Description>

The BIT type is effectively a very small integer (in fact, prior to MySQL
version 5.0.3, it was an alias for TINYINT.)  You can specify how many
bits it holds (1-64) when creating your table.  The same size should be
passed to this function. (Defaults to 1, as does MySQL.)  The function
will return the untainted integer value if it is an integer, and
can be stored within the specified number of bits.

If the $raw argument is true, the function will validate the supplied
string as a raw bit set.  i.e. '1011001'.  This matches the post-5.0.3
behavior with the 'b' flag.  i.e. b'1011001'.  In this case, the only
legal values are 0 and 1, and the length must be <= $size.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $size

Optional width of the field in bits.  Defaults to 1.

=item $raw

Options raw-mode specifier.  Tells the function to validate
$value as if it were a string representation of the binary
bit field. (see above.)

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

WARNING:  This function does not yet handle integer validation correctly
for bit fields larger than the integer width on your platform (likely 32
bits.)  This is a bug, but I have not yet had a chance to convert the
code to use an arbitrary-width integer library.  Raw validation
will work correctly all the way up to 64 bits.

The function will die if the $size field is outside of the range 1-64.

The function will always return undef if $value is undefined or zero
length. If you want to allow for NULL values you'll need to check for
them in advance.

=back

=cut

sub is_bit{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $size = shift || 1;
	my $raw = shift || 0;
	
	croak "Size field is not an integer" unless is_integer($size);
	croak "Size field must be between 1 and 64" unless($size >= 1 && $size <= 64);
	
	return unless defined($value);
	return unless length($value);
	
	if($raw){
		# make sure it only contains 0 and 1
		return if $value =~ /[^0-1]/;
		return if length($value) > $size;
		
		# untaint it - none too hard at this point
		my($clean) = $value =~ /([0-1]+)/;
		return $clean;
		
	} else {
		# must be an integer
		return unless defined(is_integer($value));
		
		# must be >= 0
		return unless $value >= 0;
		
		# must be less than the maxium value expressible in this width
		# of field
		return unless $value <= (oct('0b' . ('1' x $size)));
		
		# untaint it
		my($clean) = $value =~ /(\d+)/;
		return $clean;
	}
		
}

# -------------------------------------------------------------------------------

=pod

=item B<is_tinyint> - is the value a valid TINYINT field?

  is_tinyint($value, [$unsigned]);

=over 4

=item I<Description>

The TINYINT type is an integer with a range of -128-127, or
0-255 if it is unsigned.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $unsigned

Set to true to validate against the unsigned range of the type.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

=back

=cut

sub is_tinyint{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $unsigned = shift || 0;
		
	return unless defined($value);
	return unless length($value);
	
	return unless defined(is_integer($value));
	
	my $min = -128;
	my $max = 127;
	
	if($unsigned){
		$min = 0;
		$max = 255;
	}
	
	return is_between($value, $min, $max);
}


# -------------------------------------------------------------------------------

=pod

=item B<is_boolean> - is the value a valid BOOLEAN field?

  is_boolean($value);

=over 4

=item I<Description>

The BOOLEAN (or BOOL) type is just a single-digit TINYINT. Valid
values are the same as a signed TINYINT.  MySQL has stated that they
will support a true boolean type at some point in the future.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

=back

=cut

sub is_boolean{
	my $self = shift if ref($_[0]); 
	my $value = shift;
		
	return is_tinyint($value);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_smallint> - is the value a valid SMALLINT field?

  is_smallint($value, [$unsigned]);

=over 4

=item I<Description>

The SMALLINT type is an integer with a signed range of -32768 to 32767. 
The unsigned range is 0 to 65535.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $unsigned

Set to true to validate against the unsigned range of the type.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

=back

=cut

sub is_smallint{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $unsigned = shift || 0;
		
	return unless defined($value);
	return unless length($value);
	
	return unless defined(is_integer($value));
	
	my $min = -32768;
	my $max = 32767;
	
	if($unsigned){
		$min = 0;
		$max = 65535;
	}
	
	return is_between($value, $min, $max);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_mediumint> - is the value a valid MEDIUMINT field?

  is_mediumint($value, [$unsigned]);

=over 4

=item I<Description>

The MEDIUMINT type is an integer with a signed range of -8388608 to 8388607. 
The unsigned range is 0 to 16777215.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $unsigned

Set to true to validate against the unsigned range of the type.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

=back

=cut

sub is_mediumint{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $unsigned = shift || 0;
		
	return unless defined($value);
	return unless length($value);
	
	return unless defined(is_integer($value));
	
	my $min = -8388608;
	my $max = 8388607;
	
	if($unsigned){
		$min = 0;
		$max = 16777215;
	}
	
	return is_between($value, $min, $max);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_int> - is the value a valid INTEGER field?

  is_int($value, [$unsigned]);

=over 4

=item I<Description>

The INTEGER (or INT) type is an integer with a signed range of -9223372036854775808 to to 9223372036854775807. 
The unsigned range is 0 to 18446744073709551615.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $unsigned

Set to true to validate against the unsigned range of the type.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

=back

=cut

sub is_int{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $unsigned = shift || 0;
		
	return unless defined($value);
	return unless length($value);
			
	return unless defined(is_integer($value));
	
	# note quoting the numbers so perl doesn't lose the last few
	# digits trying to cast to an integer.
	my $min = '-2147483648';
	my $max = '2147483647';
	
	if($unsigned){
		$min = 0;
		$max = '4294967295';
	}
	
	return is_between($value, $min, $max);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_bigint> - is the value a valid BIGINT field?

  is_bigint($value, [$unsigned]);

=over 4

=item I<Description>

The BIGINT type is an integer with a signed range of -9223372036854775808 to to 9223372036854775807. 
The unsigned range is 0 to 18446744073709551615.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $unsigned

Set to true to validate against the unsigned range of the type.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

=back

=cut

sub is_bigint{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $unsigned = shift || 0;
		
	return unless defined($value);
	return unless length($value);
			
	return unless defined(is_integer($value));
	
	# note quoting the numbers so perl doesn't lose the last few
	# digits trying to cast to an integer.
	my $min = '-9223372036854775808';
	my $max = '9223372036854775807';
	
	if($unsigned){
		$min = 0;
		$max = '18446744073709551615';
	}
	
	return is_between($value, $min, $max);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_float> - is the value a valid FLOAT field?

  is_float($value, [$m], [$d], [$unsigned]);

=over 4

=item I<Description>

The FLOAT type is a floating point number with a theoretical range of
-3.402823466E+38 to -1.175494351E-38, 0, 1.175494351E-38 to 3.402823466E+38.
MySQL gets a little vague on when you'll genuinely see this range, since
it is hardware-dependent.  Your milage may vary.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $m

Optional mantisa limit.  If set, only this many digits will be allowed.
If unset, or set to the empty string, the value will only be checked
against the theoretical min/max.

=item $d

Option decimal limit. If set, only this many digits will be allowed
to the right of the decimal point. If unset, or set to the empty string,
the value will only be checked against the theoretical min/max.

=item $unsigned

Set to true to restrict to positive values.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

The function will die if $m or $d are non-integers, or are less than 1.

=back

=cut

sub is_float{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $m = shift || '';
	my $d = shift || '';
	my $unsigned = shift || 0;
	
	# sanity check our flag values;
	if(defined($m) && length($m)){
		croak "Mantissa limit must be a positive integer" unless(is_integer($m) && $m > 0);
	}
	if(defined($d) && length($d)){
		croak "Decimal limit must be a positive integer" unless(is_integer($d) && $m > 0);
	}
	
	return unless defined($value);
	return unless length($value);
	return unless defined(is_numeric($value));
	
	# do this with Math::BigFloat to handle the far ends of the spectrum
	my $v = Math::BigFloat->new($value);
	
	if($unsigned){
		return unless $v->is_pos();
	}
	
	my ($man, $exp) = $v->length();
	
	if($m){
		return if $man > $m;
	}
	if($d){
		return if $exp > $d;
	}
	
	# floats have to fit between -3.402823466E+38 and -1.175494351E-38, 
	# 0, or 1.175494351E-38 to 3.402823466E+38
	my $ok = 0;
	$ok++ if $v == 0;
	$ok++ if(($v >= Math::BigFloat->new('-3.402823466E+38')) && ($v <= Math::BigFloat->new('-1.175494351E-38')));
	$ok++ if(($v >= Math::BigFloat->new('1.175494351E-38')) && ($v <= Math::BigFloat->new('3.402823466E+38')));
	
	return unless $ok;
	
	# looks ok.  Untaint it and return as a string
	($value) = $v->bstr() =~ /(.+)/;
	
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_double> - is the value a valid DOUBLE field?

  is_double($value, [$m], [$d], [$unsigned]);

=over 4

=item I<Description>

The DOUBLE type is a floating point number with a theoretical range of
1.7976931348623157E+308 to -2.2250738585072014E-308, 0,
2.2250738585072014E-308 to 1.7976931348623157E+308. MySQL gets a little
vague on when you'll genuinely see this range, since it is
hardware-dependent.  Your milage may vary.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $m

Optional mantisa limit.  If set, only this many digits will be allowed.
If unset, or set to the empty string, the value will only be checked
against the theoretical min/max.

=item $d

Option decimal limit. If set, only this many digits will be allowed
to the right of the decimal point. If unset, or set to the empty string,
the value will only be checked against the theoretical min/max.

=item $unsigned

Set to true to restrict to positive values.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

The function will die if $m or $d are non-integers, or are less than 1.

=back

=cut

sub is_double{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $m = shift || '';
	my $d = shift || '';
	my $unsigned = shift || 0;
	
	# sanity check our flag values;
	if(defined($m) && length($m)){
		croak "Mantissa limit must be a positive integer" unless(is_integer($m) && $m > 0);
	}
	if(defined($d) && length($d)){
		croak "Decimal limit must be a positive integer" unless(is_integer($d) && $m > 0);
	}
	
	return unless defined($value);
	return unless length($value);
	return unless defined(is_numeric($value));
	
	# do this with Math::BigFloat to handle the far ends of the spectrum
	my $v = Math::BigFloat->new($value);
	
	if($unsigned){
		return unless $v->is_pos();
	}
	
	my ($man, $exp) = $v->length();
	
	if($m){
		return if $man > $m;
	}
	if($d){
		return if $exp > $d;
	}
	
	# floats have to fit between -3.402823466E+38 and -1.175494351E-38, 
	# 0, or 1.175494351E-38 to 3.402823466E+38
	my $ok = 0;
	$ok++ if $v == 0;
	$ok++ if(($v >= Math::BigFloat->new('-1.7976931348623157E+308')) && ($v <= Math::BigFloat->new('-2.2250738585072014E-308')));
	$ok++ if(($v >= Math::BigFloat->new('2.2250738585072014E-308')) && ($v <= Math::BigFloat->new('1.7976931348623157E+308')));
	
	return unless $ok;
	
	# looks ok.  Untaint it and return as a string
	($value) = $v->bstr() =~ /(.+)/;
	
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_decimal> - is the value a valid DECIMAL field?

  is_decimal($value, [$m], [$d], [$unsigned]);

=over 4

=item I<Description>

The DECIMAL type is a fixed-point number that stores what would otherwise
be floating point numbers "exactly."  You specify the total
number of digits and the total number of digits after the decimal point.
As long as your number fits within that range, it will be stored exactly.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $m

Optional mantisa limit.  Defaults to 65 (max for MySQL versions > 5.0.5)

=item $d

Option decimal limit. Defaults to 30.

=item $unsigned

Set to true to restrict to positive values.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or zero-length.  You must handle
NULL values on your own.

The function will die if $m or $d are non-integers.

=back

=cut

sub is_decimal{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $m = shift || 65;
	my $d = shift || 30;
	my $unsigned = shift || 0;
	
	# sanity check our flag values;
	croak "Mantissa limit must be a positive integer" unless(is_integer($m) && $m > 0);
	croak "Decimal limit must be an integer" unless(defined(is_integer($d)));
	
	return unless defined($value);
	return unless length($value);
	return unless defined(is_numeric($value));
	
	# do this with Math::BigFloat to handle the far ends of the spectrum
	my $v = Math::BigFloat->new($value);
	
	if($unsigned){
		return unless $v->is_pos();
	}
	
	my ($man, $exp) = $v->length();
	$man = 0 unless $man;
	$exp = 0 unless $exp;
	
	if($m){
		return if $man > $m;
	}
	if($d){
		return if $exp > $d;
	}
		
	# looks ok.  Untaint it and return as a string
	($value) = $v->bstr() =~ /(.+)/;
	
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_char> - is the value a valid CHAR field?

  is_char($value, $length);

=over 4

=item I<Description>

The CHAR type is a fixed-size text field with a maximum character width
of 255 characters.  This test uses Perl's length() function to check
the field width, so it should be compatible with multi-byte character sets.

No attempt is made to check the range of the supplied characters, since
interpreting them correctly would depend on knowledge of the character
set.  Maybe something to add down the road.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $length

Length of the field in characters.  Max is 255.  See Notes below.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

The function will die if $length is not an integer, or is outside
of the 0-255 range.

Note that because we do not know much about the characters being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_char{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $length = shift;
	
	# sanity check our flag values;
	croak "Length limit must be a positive integer less than or equal to 255" unless(is_integer($length) && $length > 0 && $length <= 255);
	
	return unless defined($value);
	
	return unless length($value) <= $length;
	
	($value) = $value =~ /(.+)/;
	return '' unless defined($value); # handle empty-string case.
	return $value;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_varchar> - is the value a valid VARCHAR field?

  is_varchar($value, $length);

=over 4

=item I<Description>

The VARCHAR type is a fixed-size text field with a maximum character width
of 65,535 characters (post 5.0.3).  For our purposes, this type is identical
to CHAR (see is_char) other than the higher maximum size.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $length

Length of the field in characters.  Max is 65,535.  See Notes below.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

The function will die if $length is not an integer, or is outside
of the 0-65,535 range.

Note that because we do not know much about the characters being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_varchar{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $length = shift;
	
	# sanity check our flag values;
	croak "Length limit must be a positive integer less than or equal to 65,535" unless(is_integer($length) && $length > 0 && $length <= 65535);
	
	return unless defined($value);
	
	return unless length($value) <= $length;
	
	($value) = $value =~ /(.+)/;
	return '' unless defined($value); # handle empty-string case.
	return $value;
}


# -------------------------------------------------------------------------------

=pod

=item B<is_binary> - is the value a valid BINARY field?

  is_binary($value, $length);

=over 4

=item I<Description>

The BINARY type is identical to a CHAR, with the exception that the length
of the field is in bytes, rather than characters.  (also has differences
in how they are sorted, but that's outside the concern of this function.)

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $length

Length of the field in bytes.  Max is 255.  See Notes below.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

The function will die if $length is not an integer, or is outside
of the 0-255 range.

Note that because we do not know much about the bytes being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_binary{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $length = shift;
	
	# sanity check our flag values;
	croak "Length limit must be a positive integer less than or equal to 255" unless(is_integer($length) && $length > 0 && $length <= 255);
	
	return unless defined($value);
	{
		use bytes;
		return unless length($value) <= $length;
	}
	
	($value) = $value =~ /(.+)/;
	return '' unless defined($value); # handle empty-string case.
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_varbinary> - is the value a valid VARBINARY field?

  is_varbinary($value, $length);

=over 4

=item I<Description>

The VARBINARY is similar to VARCHAR, except that its length is specified
in bytes, rather than characters.  (also sorts differently).

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item $length

Length of the field in bytes.  Max is 65,535.  See Notes below.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

The function will die if $length is not an integer, or is outside
of the 0-65,535 range.

Note that because we do not know much about the characters being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_varbinary{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my $length = shift;
	
	# sanity check our flag values;
	croak "Length limit must be a positive integer less than or equal to 65,535" unless(is_integer($length) && $length > 0 && $length <= 65535);
	
	return unless defined($value);
	
	{
		use bytes;
		return unless length($value) <= $length;
	}
	
	($value) = $value =~ /(.+)/;
	return '' unless defined($value); # handle empty-string case.
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_tinyblob> - is the value a valid TINYBLOB field?

  is_tinyblob($value);

=over 4

=item I<Description>

The TINYBLOB is effectively a VARBINARY field with a maximum size of 
255 bytes.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Note that because we do not know much about the bytes being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_tinyblob{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return is_varbinary($value, 255);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_tinytext> - is the value a valid TINYTEXT field?

  is_tinytext($value);

=over 4

=item I<Description>

The TINYTEXT is effectively a VARCHAR field with a maximum size of 
255 characters.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Note that because we do not know much about the bytes being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_tinytext{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	
	return is_varchar($value, 255);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_blob> - is the value a valid BLOB field?

  is_blob($value);

=over 4

=item I<Description>

a BLOB is a variable-length binary field with a maximum size of 2**16 -1
bytes.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Note that because we do not know much about the bytes being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_blob{
	my $self = shift if ref($_[0]); 
	my $value = shift;
		
	return unless defined($value);
	
	{
		use bytes;
		return unless length($value) <= ((2**16) - 1);
	}
	
	($value) = $value =~ /(.+)/;
	return '' unless defined($value); # handle empty-string case.
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_text> - is the value a valid TEXT field?

  is_text($value);

=over 4

=item I<Description>

A TEXT field is a variable-length binary field with a maximum size of 2**16 -1
characters.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Note that because we do not know much about the bytes being
supplied, we cannot really untaint the string in any meaningful way.
Although the taint flag will be removed in the return, you should in
no way consider it to be "safe."

=back

=cut

sub is_text{
	my $self = shift if ref($_[0]); 
	my $value = shift;
		
	return unless defined($value);
	
	return unless length($value) <= ((2**16) - 1);
	
	($value) = $value =~ /(.+)/;
	return '' unless defined($value); # handle empty-string case.
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_mediumblob> - is the value a valid MEDIUMBLOB field?

  is_mediumblob($value);

=over 4

=item I<Description>

a MEDIUMBLOB is a variable-length binary field with a maximum size of 2**24 -1
bytes.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the ORIGINAL value on success, undef on failure.  See
notes below.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Because of the potential size of the field, this function does
not attempt to untaint the value.  (Doing so is effectively useless
anyway, since we know nothing about the format of the data.)

=back

=cut

sub is_mediumblob{
	my $self = shift if ref($_[0]); 
	my $value = shift;
		
	return unless defined($value);
	
	{
		use bytes;
		return unless length($value) <= ((2**24) - 1);
	}
	
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_mediumtext> - is the value a valid MEDIUMTEXT field?

  is_mediumtext($value);

=over 4

=item I<Description>

a MEDIUMTEXT is a variable-length text field with a maximum size of 2**24 -1
characters.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the ORIGINAL value on success, undef on failure.  See
notes below.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Because of the potential size of the field, this function does
not attempt to untaint the value.  (Doing so is effectively useless
anyway, since we know nothing about the format of the data.)

=back

=cut

sub is_mediumtext{
	my $self = shift if ref($_[0]); 
	my $value = shift;
		
	return unless defined($value);
	
	return unless length($value) <= ((2**24) - 1);
	
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_longblob> - is the value a valid LONGBLOB field?

  is_longblob($value);

=over 4

=item I<Description>

a LONGBLOB is a variable-length binary field with a maximum size of 2**32 -1
bytes.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the ORIGINAL value on success, undef on failure.  See
notes below.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Because of the potential size of the field, this function does
not attempt to untaint the value.  (Doing so is effectively useless
anyway, since we know nothing about the format of the data.)

On a related note, these fields can be up to 4G.  Passing a
value of that size to this function may not be a great idea.  Actually,
storing a value that size in a single DB field may not be that great an
idea.

=back

=cut

sub is_longblob{
	my $self = shift if ref($_[0]); 
	my $value = shift;
		
	return unless defined($value);
	
	{
		use bytes;
		return unless length($value) <= ((2**32) - 1);
	}
	
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_longtext> - is the value a valid LONGTEXT field?

  is_longtext($value);

=over 4

=item I<Description>

a LONGTEXT is a variable-length binary field with a maximum size of 2**32 -1
characters.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=back

=item I<Returns>

Returns the ORIGINAL value on success, undef on failure.  See
notes below.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.  An empty string is considered valid.

Because of the potential size of the field, this function does
not attempt to untaint the value.  (Doing so is effectively useless
anyway, since we know nothing about the format of the data.)

On a related note, these fields can be up to 4G.  Passing a
value of that size to this function may not be a great idea.  Actually,
storing a value that size in a single DB field may not be that great an
idea.

=back

=cut

sub is_longtext{
	my $self = shift if ref($_[0]); 
	my $value = shift;
		
	return unless defined($value);
	
	return unless length($value) <= ((2**32) - 1);
	
	return $value;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_enum> - is the value a valid ENUM field?

  is_enum($value, @set);

=over 4

=item I<Description>

An ENUM field stores a fixed number of strings efficiently as an integer
index.  This function just checks to see if the test value occurs in
the valid set.

Note that prior to version MySQL 4.1.1, ENUM values were compared in a 
case-insensitive fashion.  Post 4.1.1, ENUMs can be assigned a character
set and collation, which may make them case sensitive.  Since this
function doesn't know your version or character set, it defaults
to being case sensitive to be on the safe side.

=item I<Arguments>

=over 4

=item $value

The potential value to test.

=item @set

Array of valid values.

=back

=item I<Returns>

Returns the untainted value on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined or empty.  You must handle
NULL values on your own.

The untainting system is guaranteed to return a string identical to
one in @set, so (assuming you can trust the origins of @set) you can
trust the untainted value.

This function turns the value set into a lookup hash each time it's called.
If you have a very large enum set, or a large number of values to check,
you may do better to roll your own check with a cached lookup hash.

=back

=cut

sub is_enum{
	my $self = shift if ref($_[0]); 
	my $value = shift;
	my @set = @_;
	
	return unless defined($value);
	return unless length($value);
	
	# turn the set into a lookup hash
	my %lookup;
	@lookup{@set} = ();
	
	if(exists($lookup{$value})){
		# untaint
		($value) = $value =~ /(.+)/;
		return $value;
	}
	return;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_set> - is the value a valid SET field?

  is_set(\@values, @set);

=over 4

=item I<Description>

SET fields are similar to ENUM fields in that they select their values
from a predefined list that gets stored as an integer array index.  However,
SETs can have multiple values at the same time.

Note that the empty set is always allowed in a SET, even if the column
is declared as NOT NULL.

=item I<Arguments>

=over 4

=item \@values

The potential values to test.  Each member must exist in the @set 
array.  An empty array is always considered valid. (returns an empty array
as the 'untainted' value.)

@values (like SETs) can have a maximum of 64 values.

=item @set

Array of valid values.

=back

=item I<Returns>

Returns an array reference of untainted values on success, undef on
failure.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.

The untainting system is guaranteed to return a string identical to
one in @set, so (assuming you can trust the origins of @set) you can
trust the untainted value.

This function turns the value set into a lookup hash each time it's called.
If you have a very large enum set, or a large number of values to check,
you may do better to roll your own check with a cached lookup hash.

=back

=cut

sub is_set{
	my $self = shift if ref($_[0]) && ref($_[0]) ne 'ARRAY'; 
	my $values = shift || return;
	my @set = @_;
	
	croak "Values must be an array reference" unless(ref($values) && ref($values) eq 'ARRAY');
	
	return [] unless scalar(@{$values});
	return if scalar(@{$values}) > 64;
	
	# turn the set into a lookup hash
	my %lookup;
	@lookup{@set} = ();
	my @results;
	
	my $ok = 1;
	foreach my $v (@{$values}){
		$ok = 0 unless exists $lookup{$v};
		last unless $ok;
		
		# untaint this value and add it to our collection
		my($clean) = $v =~ /(.+)/;
		push(@results, $clean);
	}
	
	return unless $ok;
	return \@results;
	
}

# -------------------------------------------------------------------------------

=pod

=item B<is_date> - is the value a valid DATE field?

  is_date($value);

=over 4

=item I<Description>

DATE fields store year, month and day values from 1000-01-01 to
9999-12-31.  They can be set using a wide variety of input formats:

=over 4

=item YYYY-MM-DD HH:MM:SS

=item YY-MM-DD HH:MM:SS

=item YYYY-MM-DD

=item YY-MM-DD

=item YYYYMMDDHHMMSS

=item YYMMDDHHMMSS

=item YYYYMMDD

=item YYMMDD

=back

DATE fields simply ignore any time-related fields you may include.

This function attempts to recognize and validate all the formats above,
though it is currently fairly naive regarding ranges. (i.e. it won't
stop you from having a day that can't exist in the month you've specified.)
Future versions of this module may correct that.

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Unlike most other Data::Validate functions, this one returns the
value in an untainted canonical (YYYY-MM-DD 00:00:00) format, regardless
of the format you supplied.  Invalid values return undef.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.

=back

=cut

sub is_date{
	my $self = shift if ref($_[0]);
	my $value = shift || return;
	
	my($status,$y,$m,$d,@t) = _parse_datetime($value);
	return unless $status;
	
	return sprintf("%04d-%02d-%02d 00:00:00", $y,$m,$d);
}

# -------------------------------------------------------------------------------

=pod

=item B<is_datetime> - is the value a valid DATETIME field?

  is_datetime($value);

=over 4

=item I<Description>

DATETIME fields store year, month, day, hour, minute, and secod values from 
1000-01-01 00:00:00 to 9999-12-31 23:59:59.

See is_date() for possible formats and caveats.  

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Unlike most other Data::Validate functions, this one returns the
value in an untainted canonical (YYYY-MM-DD HH:MM:SS) format, regardless
of the format you supplied.  Invalid values return undef.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.

=back

=cut

sub is_datetime{
	my $self = shift if ref($_[0]);
	my $value = shift || return;
	
	my($status,$y,$m,$d,$hr,$min,$sec) = _parse_datetime($value);
	return unless $status;
	
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $y,$m,$d,$hr || 0,$min || 0,$sec || 0);
}


# -------------------------------------------------------------------------------

=pod

=item B<is_timestamp> - is the value a valid TIMESTAMP field?

  is_timestamp($value);

=over 4

=item I<Description>

TIMESTAMP fields are similar to DATETIME as far as how they are
set and displayed.  They have other auto-updating behavior of course,
but it doesn't have much bearing on validation.

The major difference between the two is range - TIMESTAMPS are stored
as UNIX timestamps, and so only have a range of 1970 to 2037.

See is_date() for possible formats and caveats.  

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Unlike most other Data::Validate functions, this one returns the
value in an untainted canonical (YYYY-MM-DD HH:MM:SS) format, regardless
of the format you supplied.  Invalid values return undef.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.

=back

=cut

sub is_timestamp{
	my $self = shift if ref($_[0]);
	my $value = shift || return;
	
	my($status,$y,$m,$d,$hr,$min,$sec) = _parse_datetime($value);
	return unless $status;
	
	# reduce the valid range
	return unless($y >= 1970 && $y <= 2037);
	
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $y,$m,$d,$hr || 0,$min || 0,$sec || 0);

}


# -------------------------------------------------------------------------------

=pod

=item B<is_time> - is the value a valid TIME field?

  is_time($value);

=over 4

=item I<Description>

TIME fields seem to trip people up, since they think of them in
terms of clock time (i.e. the HH:MM:SS component of a DATETIME for
example.)  However, they are really more a representation of elapsed
time.  (Which is why they can be greater than 24 hours, or even be
negative.)

Valid range is -838:59:59' to '838:59:59'.  They can be specified
in a number of different ways:

=over 4

=item D HH:MM:SS.fraction 

=item HH:MM:SS.fraction 

=item HH:MM:SS 

=item HH:MM 

=item D HH:MM:SS 

=item D HH:MM 

=item D HH 

=item HHMMSS 

=item HHMMSS.fraction 

=item MMSS

=item SS 

=back

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Unlike most other Data::Validate functions, this one returns the
value in an untainted canonical ([H]HH:MM:SS) format, regardless
of the format you supplied.  Invalid values return undef.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.

=back

=cut

sub is_time{
	my $self = shift if ref($_[0]);
	my $value = shift || return;
	
	my($status,$hr,$min,$sec) = _parse_time($value);
	return unless $status;
	
	# validate our ranges
	return unless($hr >= -838 && $hr <= 838);
	return unless($min >= 0 && $min <= 59);
	return unless($sec >= 0 && $sec <= 59);
	
	return sprintf("%02d:%02d:%02d", $hr,$min,$sec);

}


# -------------------------------------------------------------------------------

=pod

=item B<is_year> - is the value a valid YEAR field?

  is_year($value);

=over 4

=item I<Description>

YEAR fields store a 4-digit year in a single byte field.  Range
is 1901 to 2155.  You can enter years in several formats:

=over 4

=item YYYY

=item YY

=item Y

=back

=item I<Arguments>

=over 4

=item $value

The value to test.

=back

=item I<Returns>

Unlike most other Data::Validate functions, this one returns the
value in an untainted canonical (YYYY) format, regardless
of the format you supplied.  Invalid values return undef.

=item I<Notes, Exceptions, & Bugs>

Always returns undef if $value is undefined.  You must handle
NULL values on your own.

=back

=cut

sub is_year{
	my $self = shift if ref($_[0]);
	my $value = shift || return;
	
	my $y;
	
	if($value =~ m!^(\d{4})$!){
		$y = $1;
		
	} elsif($value =~ m!^(\d{1,2})$!){
		$y = $1;
		if($y <= 69){
			$y += 2000;
		} else {
			$y += 1900;
		}
	} else {
		# invalid format
		return;
	}
	
	# check the year range
	return unless($y >= 1901 && $y <= 2155);
	
	return sprintf("%04d", $y);
		
}

sub _parse_time{
	my $v = shift || return;
	
	# SS
	if($v =~ m!^(\d{2})$!){
		return(1,0,0,$1);
	}
	
	# [D ]HH[:MM][:SS][.fraction]
	if($v =~ m!^(?:(\d{1,2})\s{1,2})?(\-?\d{1,2})(?::(\d{1,2}))?(?::(\d{1,2}))?(?:\.\d+)?$!){
		my($d,$h,$m,$s) = ($1,$2,$3,$4);
		$d = 0 unless $d;
		$s = 0 unless $s;
		$m = 0 unless $m;
		
		# D must be <= 34
		# mysql is a little vague as to whether it can be negative...
		return unless ($d >= 0 && $d <= 34);
		
		# combine the days into the hours
		$h += ($d * 24);
		
		return(1,$h,$m,$s);
	}
	
	# HHMMSS[.fraction]
	if($v =~ m!^(\d{2})(\d{2})(\d{2})(?:\.\d+)?$!){
		my($h,$m,$s) = ($1,$2,$3);
		
		return(1,$h,$m,$s);
	}
	
	# MMSS
	if($v =~ m!^(\d{2})(\d{2})$!){
		my($m,$s) = ($1,$2);
		return(1,0,$m,$s);
	}
	
	# no match - invalid format
	return;
}

sub _parse_datetime{
	my $v = shift || return;
	
	# try to match the general type
	# YYYY-MM-DD HH:MM:SS
	if($v =~ m!(^\d{4})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})\s{1,3}(\d{1,2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})$!){
		
		my @bits = ($1,$2,$3,$4,$5,$6);
		return unless _validate_date(@bits);
		return unless _validate_time(@bits);
		
		return(1,@bits);
	}
	
	# YY-MM-DD HH:MM:SS
	if($v =~ m!(^\d{2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})\s{1,3}(\d{1,2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})$!){
		
		my @bits = ($1,$2,$3,$4,$5,$6);
		
		# normalize the year following mysql's rules
		if($bits[0] <= 69){
			$bits[0] += 2000;
		} else {
			$bits[0] += 1900;
		}
		
		return unless _validate_date(@bits);
		return unless _validate_time(@bits);
		
		return(1,@bits);
	}
	
	# YYYY-MM-DD
	if($v =~ m!(^\d{4})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})$!){
		
		my @bits = ($1,$2,$3);
		return unless _validate_date(@bits);
		return(1,@bits);
	}
	
	# YY-MM-DD
	if($v =~ m!(^\d{2})[[:punct:]](\d{1,2})[[:punct:]](\d{1,2})$!){
		
		my @bits = ($1,$2,$3);
		
		# normalize the year following mysql's rules
		if($bits[0] <= 69){
			$bits[0] += 2000;
		} else {
			$bits[0] += 1900;
		}
		return unless _validate_date(@bits);
		
		return(1,@bits);
	}
	
	# YYYYMMDDHHMMSS
	if($v =~ m!^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$!){
		
		my @bits = ($1,$2,$3,$4,$5,$6);
		return unless _validate_date(@bits);
		return unless _validate_time(@bits);
		
		return(1,@bits);
	}
	
	# YYMMDDHHMMSS
	if($v =~ m!^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$!){
		my @bits = ($1,$2,$3,$4,$5,$6);
		
		# normalize the year following mysql's rules
		if($bits[0] <= 69){
			$bits[0] += 2000;
		} else {
			$bits[0] += 1900;
		}
		return unless _validate_date(@bits);
		return unless _validate_time(@bits);
		
		return(1,@bits);
	}
	
	# YYYYMMDD
	if($v =~ m!^(\d{4})(\d{2})(\d{2})$!){
		my @bits = ($1,$2,$3);
		
		return unless _validate_date(@bits);
		
		return(1,@bits);
	}
	
	# YYMMDD
	if($v =~ m!^(\d{2})(\d{2})(\d{2})$!){
		my @bits = ($1,$2,$3);
		
		# normalize the year following mysql's rules
		if($bits[0] <= 69){
			$bits[0] += 2000;
		} else {
			$bits[0] += 1900;
		}
		
		return unless _validate_date(@bits);
		
		return(1,@bits);
	}
	
	# no match - invalid format.
	return;
}

sub _validate_date{
	my($y,$m,$d,$hr,$min,$sec) = @_;
	
	# check our y/m/d ranges
	return unless($y >= 1000 && $y <= 9999);
	return unless($m >= 1 && $m <= 12);
	return unless($d >= 1 && $m <= 31);
	
	return 1;
}

sub _validate_time{
	my($y,$m,$d,$hr,$min,$sec) = @_;
	
	# check the time ranges
	return unless($hr >= 0 && $hr <= 23);
	return unless($min >= 0 && $min <= 59);
	return unless($sec >= 0 && $sec <= 59);
	
	return 1;
}

=pod

=back

=head1 AUTHOR

Richard Sonnen <F<sonnen@richardsonnen.com>>.

=head1 COPYRIGHT

Copyright (c) 2005 Richard Sonnen. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__
