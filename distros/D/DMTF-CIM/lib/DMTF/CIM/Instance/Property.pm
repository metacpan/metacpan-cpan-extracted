package DMTF::CIM::Instance::Property;

use warnings;
use strict;

use version;
our $VERSION = qv('0.04');
require DMTF::CIM::_valued;

our @ISA=qw(DMTF::CIM::_valued);
use Carp;

# Module implementation here
sub new
{
	my $class=shift;
	my %args=@_;
	my $self=DMTF::CIM::_valued::new($class, parent=>$args{parent}, data=>$args{property}, value=>$args{value});
	return($self);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::CIM::Instance::Property - Provides access to properties from a L<DMTF::CIM::Instance>


=head1 VERSION

This document describes DMTF::CIM::Instance::Property version 0.04


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

This class is returned by the property method of L<DMTF::CIM::Instance> 
It is not expected to be used by itself.

=head1 INTERFACE 

The returned object behaves as described in the "OBJECTS" section of L<DMTF::CIM>
for valued objects.

=head2 METHODS

=over

=item C<< new ( [ property=>I<property_def> ] [, value=>I<valueref> ] ) >>

Creates a new property with the CIM property description I<property_def>
and a value stored at I<valueref>.

=back

=head1 DIAGNOSTICS

This class carp()s and returns undef (or empty list) on all errors.

=head1 CONFIGURATION AND ENVIRONMENT

DMTF::CIM::Instance::Property requires no configuration files or environment variables.

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
