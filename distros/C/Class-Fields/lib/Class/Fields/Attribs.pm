package Class::Fields::Attribs;

use strict;

use vars qw( @EXPORT @ISA $VERSION );
@EXPORT = qw(PUBLIC PRIVATE INHERITED PROTECTED);
require Exporter;
@ISA = qw(Exporter);
$VERSION = '0.03';

# Inheritance constants.
# Its too bad I can't use 0bXXX since its 5.6 only.
use constant PUBLIC     => 2**0;    # Open to the public, will be inherited.
use constant PRIVATE    => 2**1;    # Not to be used by anyone but that class, 
                                    # will not be inherited
use constant INHERITED  => 2**2;    # This member was inherited
use constant PROTECTED  => 2**3;    # Not to be used by anyone but that class 
                                    # and its subclasses, will be inherited.

# For backwards compatibility.
# constant.pm doesn't like leading underscores.  Damn.
sub _PUBLIC     () { PUBLIC     }
sub _PRIVATE    () { PRIVATE    }
sub _INHERITED  () { INHERITED  }
sub _PROTECTED  () { PROTECTED  }

return 'FIRE!';

__END__
=pod

=head1 NAME

  Class::Fields::Attribs - Attribute constants for use with data members


=head1 SYNOPSIS

  # Export the attribute constants
  use Class::Fields::Attribs;


=head1 DESCRIPTION

Simply exports a set of constants used for low level work on data members.
Each constant is a bitmask used to represent the type of a data member
(as in Public, Private, etc...).

The exported attributes are:

=over 4

=item PUBLIC

=item PRIVATE

=item PROTECTED

=item INHERITED

Each of these constants is a bitmask representing a possible setting
of a field attribute.  They can be combined by using a bitwise OR and
attributes can be checked for using a bitwise AND.  For example:

    # Indicate a piece of data which is both public and inherited.
    $attrib = PUBLIC | INHERITED;

    # Check to see if an attribute is protected.
    print "Protected" if $attrib & PROTECTED;

It is rare that one has to use these constants and it is generally
better to use the functions provided by Class::Fields.

=back

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=head1 SEE ALSO

L<Class::Fields>

=cut
