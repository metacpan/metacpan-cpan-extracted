package Business::AU::ABN;

# Implements algorithm for validating ABNs, detailed by the ATO at
# http://www.ato.gov.au/content/downloads/nat2956.pdf

# See POD at the end of the file

use 5.005;
use strict;
use Exporter          ();
use List::Util   1.11 ();
use Params::Util 0.25 ();
use overload '""'   => 'to_string',
             'bool' => sub () { 1 };

# The set of digit weightings, taken from the documentation.
use constant WEIGHT => qw{10 1 3 5 7 9 11 13 15 17 19};

use vars qw{$VERSION @ISA @EXPORT_OK $errstr};
BEGIN {
	$VERSION   = '1.09';
	@ISA       = 'Exporter';
	@EXPORT_OK = 'validate_abn';
	$errstr    = '';
}





#####################################################################
# Constructor

sub new {
	my $class = ref $_[0] || $_[0];

	# Validate the string to create the object for
	my $validated = $class->_validate_abn($_[1]) or return '';

	bless( \$validated, $class );
}

# The validate_abn method acts as a wrapper for the various call
# forms around the true method _validate_abn.
sub validate_abn {
	# Object method
	if ( Params::Util::_INSTANCE( $_[0], 'Business::AU::ABN' ) ) {
		return $_[0]->to_string;
	}

	# Class method
	if ( Params::Util::_CLASSISA($_[0], 'Business::AU::ABN') ) {
		return $_[0]->_validate_abn($_[1]);
	}

	# Function call
	__PACKAGE__->_validate_abn($_[0]);
}

# Do the ACTUAL check, called in class method context only.
# I've tried to keep the code here very very simple, which takes a 
# little more memory, but is much more obvious in function.
# Returns true if correct, false if not, or undef on error.
sub _validate_abn {
	my $class = shift;
	$errstr = '';

	# Make sure we at least have a string to check
	my $abn = $class->_string($_[0]) ? shift
		: return $class->_error( 'No value provided to check' );

	# Check we have only whitespace ( which we remove ) and digits
	$abn =~ s/\s+//gs;
	return $class->_error( 'ABN contains invalid characters' ) if $abn =~ /\D/;

	# Initial validation is based on the number of digits.
	# An ABN with a "group number" attached is 14 digits.
	my $group = '';
	if ( length $abn == 14 ) {
		($abn, $group) = $abn =~ /^(\d{11})(\d{3})$/ or die 'Regex unexpectedly failed';

		# Group numbers are allocated sequentially, starting at 001.
		# This means that 000 is not a legal group identifier.
		if ( $group eq '000' ) {
			return $class->_error( 'Cannot have the group identifier 000' );
		}

	} elsif ( length $abn != 11 ) {
		return $class->_error( 'ABNs are 11 digits, not ' . length $abn );
	}

	# Split the 11 digit ABN into an 11 element array
	my @digits = $abn =~ /\d/g;

	# Quotes are directly from the algorithm documentation
	# "Step 1. Subtract 1 from the first ( left ) digit to give a new 11 digit number"
	$digits[0] -= 1;

	# "Step 2. Multiply each of the digits in this new number by its weighting factor"
	@digits = map { $digits[$_] * (WEIGHT)[$_] } (0 .. 10);

	# "Step 3. Sum the resulting 11 products"
	# "Step 4. Divide the total by 89, noting the remainder"
	# "Step 5. If the remainder is zero the number is valid"
	if ( List::Util::sum(@digits) % 89 ) {
		return $class->_error( 'ABN looks correct, but fails checksum' );
	}

	# Format and return
	$abn =~ s/^(\d{2})(\d{3})(\d{3})(\d{3})$/$1 $2 $3 $4/ or die "panic!";
	length($group) ? "$abn $group" : $abn;
}

# Get the ABN as a string
sub to_string { ${$_[0]} }

# Get the error message when validation returns false.
sub errstr { $errstr }





#####################################################################
# Utility Methods

# Is a value a non-null non-whitespace string
sub _string {
	!! (defined $_[1] and ! ref $_[1] and length $_[1] and $_[1] =~ /\S/);
}

sub _error {
	$errstr = (defined $_[1] and $_[1]) ? "$_[1]" : 'Unknown error while validating ABN';
	''; # False
}

1;

__END__

=pod

=head1 NAME

Business::AU::ABN - Validate and format Australian Business Numbers

=head1 SYNOPSIS

  # Create a new validated ABN object
  use Business::AU::ABN;
  my $ABN = new Business::AU::ABN( '12 004 044 937' );
  
  # Validate in a single method call
  Business::AU::ABN->validate_abn( '12 004 044 937' );
  
  # Validate in a single function call
  Business::AU::ABN::validate_abn( '12 004 044 937' );
  
  # The validate_abn function is also importable
  use Business::AU::ABN 'validate_abn';
  validate_abn( '12 004 044 937' );

=head1 DESCRIPTION

The Australian Business Number ( ABN ) is a government allocated number
required by all businesses in order to trade in Australia. It is intented to
provide a central, universal, and unique identifier for all businesses.

It's also rather neat, in that it is capable of self-validating. Much like
a credit card number does, a simple algorithm applied to the digits can
confirm that the number is valid. ( Although the business may not actually 
exist ). The checksum algorithm was specifically designed to catch situations
in which you get two digits the wrong way around, or something of that nature.

C<Business::AU::ABN> provides a validation/formatting mechanism, and an object
form of an ABN number. ABNs are reformatted into the most preferred format,
'01 234 567 890'.

The object itself automatically stringifies to the formatted number, so with
an object, you can safely do C<print "Your ABN $ABN looks OK"> and other
things of that nature.

=head2 Highly flexible validation

Apart from the algorithm itself, most of this module is aimed at making the
validation mechanism as flexible and easy to use as possible.

With this in mind, the C<validate_abn> sub can be accessed in ANY form, and
will just "do what you mean". See the method details for more information.

Also, all validation will take just about any crap as an argument, and not die
or throw a warning. It will just return false.

=head2 "Group" ABNs

The ABN supports the concept of "Groups", that is, a group of companies
sharing a common ABN, but being seperated within it. In fact, ALL companies
that have a regular 11 digit ABN are actually also allocated a group number.
This group number is a 3 digit number, and are allocated incrementally,
starting with 001. So the ABN '01 234 567 890' is actually also capable of
being represented as '01 234 567 890 001'.

By convention, when only a single company exists, the 001 is dropped.
However, in common situations where an ABN value is expected, you accept
both the 11 digit regular version, and the 14 digit group version. The 14
digit case will also be reformatted to show the group identifier as an
additional 3 digits group.

Except for not allowing 000, there are no restrictions, and group
identifiers are not included in the checksum calculation.

=head1 METHODS

=head2 new $string

The C<new> method creates a new C<Business::AU::ABN> object. Takes as argument
a value, and validates that it is correct before creating the object. As such
if an object is provided that passes C<$ABN-E<gt>isa('Business::AU::ABN')>,
it IS a valid ABN and does not need to be checked.

Returns a new C<Business::AU::ABN> on success, or sets the error string and
returns false if the string is not an ABN.

=head2 $ABN-E<gt>validate_abn

When called as a method on an object, C<validate_abn> isn't really that useful,
as ABN objects are already assumed to be correct, but the method is included
for completeness sake.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid, or false if not.

=head2 Business::AU::ABN-E<gt>validate_abn $string

When called as a static method, C<validate_abn> takes a string as an argument and
attempts to validate it as an ABN.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 Business::AU::ABN::validate_abn $string

When called directly as a fully referenced function, C<validate_abn> responds in
exactly the same was as for the static method above.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 validate_abn $string

The C<validate_abn> function can also be imported to your package and used
directly, as in the following example.

  use Business::AU::ABN 'validate_abn';
  my $abn = '01 234 567 890';
  print "Your ABN is " . validate_abn($abn) ? 'valid' : 'invalid';

The imported function reponds identically to the fully referenced function
and the static method.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 to_string

The C<to_string> method returns the ABN as a string. 
This is also the method called by the stringification overload.

=head2 errstr

When C<validate_abn> or C<new> return false, a message describing the problem
can be accessed via any of the following.

  # Global variable
  $Business::AU::ABN::errstr
  
  # Class method
  Business::AU::ABN->errstr
  
  # Function
  Business::AU::ABN::errstr()

=head1 TO DO

Add the method C<ACN> to get the older Australian Company Number from the
ABN, which is a superset of it.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-AU-ABN>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2003 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
