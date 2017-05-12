package Data::Digest;

=pod

=head1 NAME

Data::Digest - Objects that represent a digest values

=head1 SYNOPSIS

  $digest = Data::Digest->new(
      'MD5.d41d8cd98f00b204e9800998ecf8427e'
  );
  
  $digest = Data::Digest->new(
      'SHA-256' => '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU',
  );
  
  $digest->matches( \$data );
  $digest->matches( $filename );

=head1 DESCRIPTION

The C<Data::Digest> class provides utility objects that represents
a digest value. It is used primarily as a convenience and to simplify code
when dealing with situations where you are provided with a digest, and need
to check it against some data.

It initially supports 4 different digest types, (MD5, SHA-1,
SHA-256 and SHA-512) to provide varying strengths of checking.
The default, which is intended for speed and basic non-cryptographic
file integrity checking, is MD5.

Users hand-crafting guest specifications may want to use a stronger
digest.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp         ();
use Digest       ();
use IO::File     ();
use Params::Util qw{_STRING _SCALAR0 _INSTANCE};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.04';
}

# For all supported digest types, provide the expected lengths of the digest
# in each format in bits.
# These will be used to help generate the regular expressions used to
# validate the input strings.
my %DIGEST = (
	'MD5' => {
		bits      => 128,
		digest    => 16,
		hexdigest => 32,
		b64digest => 22,
	},
	'SHA-1' => {
		bits      => 160,
		digest    => 20,
		hexdigest => 40,
		b64digest => 27,
	},
	'SHA-256' => {
		bits      => 256,
		digest    => 32,
		hexdigest => 64,
		b64digest => 43,
	},
	'SHA-512' => {
		bits      => 512,
		digest    => 64,
		hexdigest => 128,
		b64digest => 86,
	},
);





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  # Two-argument digest constructor
  $digest = Data::Digest->new(
      'SHA-256' => '47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU',
  );
  
  # One-argument digest constructor
  $digest = Data::Digest->new(
      'MD5.d41d8cd98f00b204e9800998ecf8427e'
  );

The C<new> constructor takes one or two strings parameters, and creates
a new digest object, that can be stored or used to compared the digest
value to existing data, or a file.

The basic two-argument form takes the name of a supported digest driver,
and the digest value.

The digest driver is case sensitive and should be one of C<'MD5'>,
C<'SHA-1'>, C<'SHA-256'> or C<'SHA-512'>. (case sensitive)

The second param should be a string containing the value of the digest
in either binary, hexidecimal or base 64 format.

The constructor will auto-detect the encoding type.

For example, for a 128-bit MD5 digest, the constructor will allow a
16-character binary string, a 32-character hexedecimal string, or
a 22-character base 64 string.

Returns a C<Data::Digest> object, or throws an exception on error.

=cut

sub new {
	my $class = shift;
	my ($driver, $digest, $method) = ();
	if ( @_ == 1 and _STRING($_[0]) ) {
		if ( $_[0] =~ /^(\w+(?:-\d+)?)\.(\S+)$/ ) {
			$driver = $1;
			$digest = $2;
		} else {
			Carp::croak("Unrecognised or unsupported Data::Digest string");
		}
	} elsif ( @_ == 2 and _STRING($_[0]) and _STRING($_[1]) ) {
		$driver = $_[0];
		$digest = $_[1];
	} else {
		Carp::croak("Missing or invalid params provided to Data::Digest constructor");
	}

	# Check the digest values
	my $len = $DIGEST{$driver}
		or Carp::croak("Invalid or unsupported digest type '$driver'.");

	# Check the digest content to find the method
	if ( length $digest == $len->{digest} ) {
		$method = 'digest';
	} elsif ( length $digest == $len->{hexdigest} and $digest !~ /[^0-9a-f]/ ) {
		$method = 'hexdigest';
	} elsif ( length $digest == $len->{b64digest} and $digest !~ /[^\w\+\/]/ ) {
		$method = 'b64digest';
	} else {
		Carp::croak("Digest string is not a recognised $driver");
	}

	# Create the object
	my $self = bless {
		driver => $driver,
		digest => $digest,
		method => $method,
	}, $class;

	return $self;
}

=pod

=head2 driver

The C<driver> accessor returns the digest driver name, which be one of
either C<'MD5'>, C<'SHA-1'>, C<'SHA-256'> or C<'SHA-512'>.

=cut

sub driver {
	$_[0]->{driver};
}

=pod

=head2 digest

The C<digest> accessor returns the digest value, in the original format.

This could be either binary, hexidecimal or base 64 and without knowing
what was originally entered you may not necesarily know which it will be.

=cut

sub digest {
	$_[0]->{digest};
}





#####################################################################
# Main Methods

=pod

=head2 as_string

The C<as_string> method returns the stringified form of the digest,
which will be equivalent to and suitable for use as the value passed
to the single-parameter form of the constructor.

  print $digest->as_string . "\n";
  > MD5.d41d8cd98f00b204e9800998ecf8427e

Returns a string between around 15 and 90 characters, depending on the
type and encoding of the digest value.

=cut

sub as_string {
	$_[0]->driver . '.' . $_[0]->digest;
}

=pod

=head2 matches

  # Check the digest against something
  $digest->matches( $filename  );
  $digest->matches( $io_handle );
  $digest->matches( \$string   );

The C<matches> methods checks the digest object against various forms of
arbitrary data to determine if they match the digest.

It takes a single parameter, consisting of either the name of a file,
an L<IO::Handle> object, or the reference to a C<SCALAR> string.

Returns true if the digest matches the data, false if not, or throws
an exception on error.

=cut

sub matches {
	my $self = shift;
	return $self->_matches_file(shift)   if _STRING($_[0]);
	return $self->_matches_scalar(shift) if _SCALAR0($_[0]);
	return $self->_matches_handle(shift) if _INSTANCE($_[0], 'IO::Handle');
	Carp::croak("Did not provide a valid data value to check digest against");
}

sub _matches_scalar {
	my ($self, $scalar_ref) = @_;

	# Generate the digest for the string
	my $method = $self->{method};
	my $digest = $self->_digest->add($$scalar_ref)->$method();

	return ($self->digest eq $digest);
}

sub _matches_file {
	my ($self, $file) = @_;

	# Check the filename
	-f $file or Carp::croak("File '$file' does not exist");
	-r $file or Carp::croak("No permissions to read '$file'");

	# Load and generate the digest for the file
	my $handle = IO::File->new($file)
		or Carp::croak("Failed to load '$file': $!");
	return $self->_matches_handle($handle);
}

sub _matches_handle {
	my ($self, $handle) = @_;

	# Generate the digest for the handle
	my $method = $self->{method};
	my $digest = $self->_digest->addfile($handle)->$method();

	return ($self->digest eq $digest);
}

sub _digest {
	my $self = shift;
	Digest->new($self->driver)
		or die("Failed to create Digest object");
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Digest>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Digest>, L<Digest::MD5>, L<Digest::SHA>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
