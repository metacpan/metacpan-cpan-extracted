package DMTF::CIM::Instance::Method::Parameter;

use warnings;
use strict;

use version;
our $VERSION = qv('0.04');
require DMTF::CIM::_model;
use Carp;

our @ISA=qw(DMTF::CIM::_valued);

# Module implementation here
sub new
{
	my $class=shift;
	my %args=@_;
	my $self=DMTF::CIM::_valued::new($class,parent=>$args{parent},data=>$args{parameter},value=>$args{value});
	return($self);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::CIM::Instance::Method::Parameter - Provides access to method parameters from a L<DMTF::CIM::Instance::Method>


=head1 VERSION

This document describes DMTF::CIM::Instance::Method::Parameter version 0.04


=head1 SYNOPSIS

  use DMTF::CIM::WSMan;
  my $cim=DMTF::CIM::WSMan->new();

  my $instance = $cim->get('wsman.wbem://host:623/interop:CIM_ManagedElement.InstanceID=1');

  print $instance->class,"\n";
  foreach my $prop ( $instance->defined_properties ) {
	  my $prop = $instance->property($prop);
      print "$prop: ",$prop->value,"\n";
  }


=head1 DESCRIPTION

This class is returned by the parammeter method of L<DMTF::CIM::Instance::Method> 
It is not expected to be used by itself.

=head1 INTERFACE 

=head2 METHODS

=over

=item C<< new ( [ property=>I<property_def> ] [, value=>I<valueref> ] ) >>

Creates a new parameter with the CIM parameter description I<property_def>
and a value stored at I<valueref>.

=item C<< name >>

Returns the name of the parameter using the defined case.

=item C<< value ( [ I<newvalue> ] ) >>

If the I<newvalue> list is specified, sets the value to that.  Returns the
current mapped value.  If the parameter is an array, and the method is used
in a scalar context, the values are join(', ')ed.

=item C<< raw_value ( [ I<newvalue> ] ) >>

If the I<newvalue> list is specified, sets the value to that.  Returns the
current unmapped value.  If the parameter is an array, and the method is used
in a scalar context, the values are join(', ')ed.

=item C<< is_array ( ) >>

Returns a true value equal to the length of the array if the parameter
is an array or 0 otherwise.  A zero-length array returns '0 but true'

=item C<< is_ref ( ) >>

Returns true if the parameter is a reference or false otherwise.

=item C<< type ( ) >>

Returns the type name of the parameter.  If the parameter is an
array, will have '[]' appended.  For properties which have no type information
in the instance, the type is assumed to be 'string'.

CIM types as of this writing are:

=over

=item uint8

=item uint16

=item uint32

=item uint64

=item sint8

=item sint16

=item sint32

=item sint64

=item real32

=item real64

=item string

=item char16

=item boolean

=item datetime

=back

The name of the target class, or 'ref' is returned for references.

=item C<< qualifier( I<name> ) >>

Returns the value of the qualifier with I<name>.

=back

=head1 DIAGNOSTICS

This class carp()s and returns undef (or empty list) on all errors.

=head1 CONFIGURATION AND ENVIRONMENT

DMTF::CIM::Instance::Method::Parameter requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dmtf-cim-instance@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Stephen James Hurd  C<< <shurd@broadcom.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Broadcom Corporation C<< <shurd@broadcom.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
