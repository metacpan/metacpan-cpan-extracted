package Data::JavaScript::Anon;

# This package provides a mechanism to convert the main basic Perl
# structures into JavaScript structures, making it easier to transfer
# data from Perl to JavaScript.

use 5.006;
use strict;
use warnings;
use Params::Util   qw{ _STRING _SCALAR0 _ARRAY0 _HASH0 };
use Class::Default ();

use vars qw{@ISA $VERSION $errstr $RE_NUMERIC $RE_NUMERIC_HASHKEY %KEYWORD};
BEGIN {
	$VERSION = '1.03';
	@ISA     = 'Class::Default';
	$errstr  = '';

	# Attempt to define a single, all encompasing,
	# regex for detecting a legal JavaScript number.
	# We do not support the exotic values, such as Infinite and NaN.
	my $_sci = qr/[eE](?:\+|\-)?\d+/;                   # The scientific notation exponent ( e.g. 'e+12' )
	my $_dec = qr/\.\d+/;                               # The decimal section ( e.g. '.0212' )
	my $_int = qr/(?:[1-9]\d*|0)/;                      # The integers section ( e.g. '2312' )
	my $real = qr/(?:$_int(?:$_dec)?|$_dec)(?:$_sci)?/; # Merge the integer, decimal and scientific parts
	my $_hex = qr/0[xX][0-9a-fA-F]+/;                   # Hexidecimal notation
	my $_oct = qr/0[0-7]+/;                             # Octal notation

	# The final combination of all posibilities for a straight number
	# The string to match must have no extra characters
	$RE_NUMERIC = qr/^(?:\+|\-)??(?:$real|$_hex|$_oct)\z/;

	# The numeric for of the hash key is similar, but without the + or - allowed
	$RE_NUMERIC_HASHKEY = qr/^(?:$real|$_hex|$_oct)\z/;

	%KEYWORD = map { $_ => 1 } qw{
		abstract boolean break byte case catch char class const
		continue debugger default delete do double else enum export
		extends false final finally float for function goto if
		implements import in instanceof int interface long native new
		null package private protected public return short static super
		switch synchronized this throw throws transient true try typeof
		var void volatile while with
	};
}





#####################################################################
# Top Level Dumping Methods

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $opts  = _HASH0($_[0]) ? shift : { @_ };

	# Create the object
	my $self = bless {
		quote_char => '"',
	}, $class;

	## change the default quote character
	if ( defined $opts->{quote_char} && length $opts->{quote_char} ) {
		$self->{quote_char} = $opts->{quote_char};
	}

	return $self;
}

sub _create_default_object {
	my $class = shift;
	my $self  = $class->new();
	return $self;
}

sub anon_dump {
	my $class     = shift;
	my $something = shift;
	my $processed = shift || {};

	# Handle the undefined case
	return 'undefined' unless defined $something;

	# Handle the basic non-reference case
	return $class->anon_scalar( $something ) unless ref $something;

	# Check to see if we have processed this reference before.
	# This should catch circular, cross-linked, or otherwise complex things
	# that we can't handle.
	if ( $processed->{$something} ) {
		return $class->_err_found_twice( $something );
	} else {
		$processed->{$something} = 1;
	}

	# Handle the SCALAR reference case, which in our case we treat
	# like a normal scalar.
	if ( _SCALAR0($something) ) {
		return $class->anon_scalar( $something );
	}

	# Handle the array case by generating an anonymous array
	if ( _ARRAY0($something) ) {
		# Create and return the array
		my $list = join ', ', map { $class->anon_dump($_, $processed) } @$something;
		return "[ $list ]";
	}

	# Handle the hash case by generating an anonymous object/hash
	if ( _HASH0($something) ) {
		# Create and return the anonymous hash
		my $pairs = join ', ', map {
			$class->anon_hash_key($_)
				. ': '
				. $class->anon_dump( $something->{$_}, $processed )
		} keys %$something;
		return "{ $pairs }";
	}

	$class->_err_not_supported( $something );
}

# Same thing, but creating a variable
sub var_dump {
	my $class = shift;
	my $name  = shift or return undef;
	my $value = $class->anon_dump( shift );
	"var $name = $value;";
}

# Wrap some JavaScript in a HTML script tag
sub script_wrap {
	"<script language=\"JavaScript\" type=\"text/JavaScript\">\n$_[1]\n</script>";
}

# Is a particular string a legal JavaScript number.
# Returns true if a legal JavaScript number.
# Returns false otherwise.
sub is_a_number {
	my $class  = shift;
	my $number = (defined $_[0] and ! ref $_[0]) ? shift : '';
	$number =~ m/$RE_NUMERIC/ ? 1 : '';
}





#####################################################################
# Basic Variable Creation Statements

# Create a JavaScript scalar given the javascript variable name
# and a reference to the scalar.
sub var_scalar {
	my $class      = shift;
	my $name       = shift or return undef;
	my $scalar_ref = _SCALAR0(shift) or return undef;
	my $value      = $class->js_value( $$scalar_ref ) or return undef;
	"var $name = $value;";
}

# Create a JavaScript array given the javascript array name
# and a reference to the array.
sub var_array {
	my $class     = shift;
	my $name      = shift or return undef;
	my $array_ref = _ARRAY0(shift) or return undef;
	my $list      = join ', ', map { $class->anon_dump($_) } @$array_ref;
	"var $name = new Array( $list );";
}

# Create a JavaScript hash ( which is just an object ), given
# the variable name, and a reference to a hash.
sub var_hash {
	my $class    = shift;
	my $name     = shift or return undef;
	my $hash_ref = _HASH0(shift) or return undef;
	my $struct   = $class->anon_hash( $name, $hash_ref ) or return undef;
	"var $name = $struct;";
}





#####################################################################
# Basic Serialisation And Escaping Methods

# Turn a single perl value into a single javascript value
sub anon_scalar {
	my $class = shift;
	my $value = _SCALAR0($_[0]) ? ${shift()} : shift;
	return 'null' unless defined $value;

	# Don't quote if it is numeric
	return $value if $value =~ /$RE_NUMERIC/;

	my $quote_char = $class->_self->{quote_char};

	# Escape and quote
	$quote_char . $class->_escape($value) . $quote_char;
}

# Turn a single perl value into a javascript hash key
sub anon_hash_key {
	my $class = shift;
	my $value = defined($_[0]) && !ref($_[0]) ? shift : return undef;

	my $quote_char = $class->_self->{quote_char};

	# Quote if it's a keyword
	return $quote_char . $value . $quote_char if $KEYWORD{$value};

	# Don't quote if it is just a set of word characters or numeric
	return $value if $value =~ /^[^\W\d]\w*\z/;
	return $value if $value =~ /$RE_NUMERIC_HASHKEY/;

	# Escape and quote
	$quote_char . $class->_escape($value) . $quote_char;
}

# Create a JavaScript array given the javascript array name
# and a reference to the array.
sub anon_array {
	my $class     = shift;
	my $name      = shift or return undef;
	my $array_ref = _ARRAY0(shift) or return undef;
	my $list      = join ', ', map { $class->anon_scalar($_) } @$array_ref;
	"[ $list ]";
}

# Create a JavaScript hash ( which is just an object ), given
# the variable name, and a reference to a hash.
sub anon_hash {
	my $class    = shift;
	my $name     = shift or return undef;
	my $hash_ref = _HASH0(shift) or return undef;
	my $pairs    = join ', ', map { 
		$class->anon_hash_key( $_ )
			. ': '
			. $class->anon_scalar( $hash_ref->{$_} )
	} keys %$hash_ref;
	"{ $pairs }";
}





#####################################################################
# Utility and Error Methods

sub _escape {
	my $class = shift;
	my $text  = shift;
	my $char  = $class->_self->{quote_char};
	$text =~ s/(\Q$char\E|\\)/\\$1/g;                       # Escape quotes and backslashes
	$text =~ s/\n/\\n/g;                                    # Escape newlines in a readable way
	$text =~ s/\r/\\r/g;                                    # Escape CRs in a readable way
	$text =~ s/\t/\\t/g;                                    # Escape tabs in a readable way
	$text =~ s/([\x00-\x1F])/sprintf("\\%03o", ord($1))/ge; # Escape other control chars as octal
	$text;
}

sub _err_found_twice {
	my $class     = shift;
	my $something = ref $_[0] || 'a reference';
	$errstr = "Found $something in your dump more than once. "
		. "Data::JavaScript::Anon does not support complex, "
		. "circular, or cross-linked data structures";
	undef;
}

sub _err_not_supported {
	my $class     = shift;
	my $something = ref $_[0] || 'A reference of unknown type';
	$errstr = "$something was found in the dump struct. "
		. "Data::JavaScript::Anon only supports objects based on, "
		. "or references to SCALAR, ARRAY and HASH type variables.";
	undef;
}

1;

__END__

=pod

=head1 NAME

Data::JavaScript::Anon - Dump big dumb Perl structs to anonymous JavaScript structs

=head1 SYNOPSIS

  # Dump an arbitrary structure to javascript
  Data::JavaScript::Anon->anon_dump( [ 'a', 'b', { a => 1, b => 2 } ] );

=head1 DESCRIPTION

Data::JavaScript::Anon provides the ability to dump large simple data
structures to JavaScript. That is, things that don't need to be a class,
or have special methods or whatever.

The method it uses is to write anonymous variables, in the same way you
would in Perl. The following shows some examples.

  # Perl anonymous array
  [ 1, 'a', 'Foo Bar' ]
  
  # JavaScript equivalent ( yes, it's exactly the same )
  [ 1, 'a', 'Foo Bar' ]
  
  # Perl anonymous hash
  { foo => 1, bar => 'bar' }
  
  # JavaScript equivalent
  { foo: 1, bar: 'bar' }

One advantage of doing it in this method is that you do not have to
co-ordinate variable names between your HTML templates and Perl. You
could use a simple Template Toolkit phrase like the following to get
data into your HTML templates.

  var javascript_data = [% data %];

In this way, it doesn't matter WHAT the HTML template calls a
particular variables, the data dumps just the same. This could help
you keep the work of JavaScript and Perl programmers ( assuming you
were using different people ) seperate, without creating 
cross-dependencies between their code, such as variable names.

The variables you dump can also be of arbitrary depth and complexity,
with a few limitations.

=over 4

=item ARRAY and HASH only

Since arrays and hashs are all that is supported by JavaScript, they
are the only things you can use in your structs. Any references or a
different underlying type will be detected and an error returned.

Note that Data::JavaScript::Anon will use the UNDERLYING type of the
data. This means that the blessed classes or objects will be ignored
and their data based on the object's underlying implementation type.

This can be a positive thing, as you can put objects for which you expect
a certain dump structure into the data to dump, and it will convert to 
unblessed, more stupid, JavaScript objects cleanly.

=item No Circular References

Since circular references can't be defined in a single anonymous struct,
they are not allowed. Try something like L<Data::JavaScript> instead.
Although not supported, they will be detected, and an error returned.

=back

=head1 MAIN METHODS

All methods are called as methods directly, in the form
C<< Data::JavaScript::Anon->anon_dump( [ 'etc' ] ) >>.

=head2 anon_dump STRUCT

The main method of the class, anon_dump takes a single arbitrary data
struct, and converts it into an anonymous JavaScript struct.

If needed, the argument can even be a normal text string, although it
wouldn't do a lot to it. :)

Returns a string containing the JavaScript struct on success, or C<undef>
if an error is found.

=head2 var_dump $name, STRUCT

As above, but the C<var_dump> method allows you to specify a variable name,
with the resulting JavaScript being C<var name = struct;>. Note that the
method WILL put the trailing semi-colon on the string.

=head2 script_wrap $javascript

The C<script_wrap> method is a quick way of wrapping a normal JavaScript html
tag around your JavaScript.

=head2 is_a_number $scalar

When generating the javascript, numbers will be printed directly and not
quoted. The C<is_a_number> method provides convenient access to the test
that is used to see if something is a number. The test handles just about
everything legal in JavaScript, with the one exception of the exotics, such
as Infinite, -Infinit and NaN.

Returns true is a scalar is numeric, or false otherwise.

You may also access method in using an instantiated object.

=head2 new HASH

This will create a Data::JavaScript::Anon object that will allow you to change
some of the default behaviors of some methods.

    Options:
        quote_char  : Set the quote_char for stirng scalars. Default is '"'.

=head1 SECONDARY METHODS

The following are a little less general, but may be of some use.

=head2 var_scalar $name, \$scalar

Creates a named variable from a scalar reference.

=head2 var_array $name, \@array

Creates a named variable from an array reference.

=head2 var_hash $name, \%hash

Creates a named variable from a hash reference.

=head2 anon_scalar \$scalar

Creates an anonymous JavaScript value from a scalar reference.

=head2 anon_array \@array

Creates an anonymous JavaScript array from an array reference.

=head2 anon_hash \%hash

Creates an anonymous JavaScript object from a hash reference.

=head2 anon_hash_key $value

Applys the formatting for a key in a JavaScript object

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-JavaScript-Anon>

For other comments or queries, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<JSON>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2003 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
