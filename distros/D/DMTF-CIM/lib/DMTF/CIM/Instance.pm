package DMTF::CIM::Instance;

use warnings;
use strict;

use version;
our $VERSION = qv('0.04');
require DMTF::CIM::_model;

our @ISA=qw(DMTF::CIM::_model);

use DMTF::CIM::Instance::Property;
use DMTF::CIM::Instance::Method;
use Carp;

# Module implementation here
sub new
{
	my $class=shift;
	my %args=@_;
	my $self=DMTF::CIM::_model::new($class,$args{parent},$args{class});
	$self->{VALUES}=$args{values} || {};
	$self->{PROPERTIES}={};
	$self->{METHODS}={};
	if(defined $args{uri}) {
		$self->{URI}=URI->new($args{uri});
	}
	return($self);
}

sub property
{
	my $self=shift;
	my $name=shift;

	if(!defined $name) {
		carp("No property name specified for property() of $self->{DATA}{name}");
		return;
	}
	return($self->{PROPERTIES}{lc($name)}) if defined $self->{PROPERTIES}{lc($name)};
	my $propref=$self->{DATA}{properties}{lc($name)};
	if(!defined $propref) {
		$propref=$self->{DATA}{references}{lc($name)};
	}
	if(!defined $propref) {
		carp("$self->{DATA}{name}.$name is not defined in the model");
		return;
	}
	$self->{VALUES}{$propref->{name}}=undef unless exists $self->{VALUES}{$propref->{name}};
	$self->{PROPERTIES}{lc($name)}=DMTF::CIM::Instance::Property->new(parent=>$self,property=>$propref,value=>\$self->{VALUES}{$propref->{name}});
	return $self->{PROPERTIES}{lc($name)};
}

sub method
{
	my $self=shift;
	my $name=shift;

	if(!defined $name) {
		carp("No method name specified for method() of $self->{DATA}{name}");
		return;
	}
	return($self->{METHODS}{lc($name)}) if defined $self->{METHODS}{lc($name)};
	my $methodref=$self->{DATA}{methods}{lc($name)};
	if(!defined $methodref) {
		carp("$self->{DATA}{name}.$name() is not defined in the model");
		return;
	}
	$self->{METHODS}{lc($name)}=DMTF::CIM::Instance::Method->new(parent=>$self,method=>$methodref);
	return $self->{METHODS}{lc($name)};
}

sub uri
{
	my $self=shift;
	my $newuri=shift;
	if(defined($newuri)) {
		$self->{URI}=URI->new($newuri);
	}
	my $uri=$self->{URI}->canonical;
	if(ref($uri)) {
		return $$uri;
	}
	return $uri;
}

# Read-only
sub class
{
	my $self=shift;
	return $self->name;
}

sub is_association
{
	my $self=shift;

	return 1 if(defined $self->{DATA}{qualifiers}{association} && $self->{DATA}{qualifiers}{association}{value} eq 'true');
	return 0;
}

sub defined_properties
{
	my $self=shift;
	my @ret;
	foreach my $prop (sort keys(%{$self->{VALUES}})) {
		if(defined $self->{VALUES}{$prop}) {
			my $newprop=$self->property($prop);
			push @ret,$newprop if defined $newprop;
		}
	}
	return @ret;
}

sub all_properties
{
	my $self=shift;
	my @ret;
	foreach my $prop (sort keys(%{$self->{DATA}{properties}})) {
		if(defined $self->{DATA}{properties}{$prop}{name}) {
			my $newprop=$self->property($prop);
			push @ret,$newprop if defined $newprop;
		}
	}
	foreach my $prop (sort keys(%{$self->{DATA}{references}})) {
		if(defined $self->{DATA}{references}{$prop}{name}) {
			my $newprop=$self->property($prop);
			push @ret,$newprop if defined $newprop;
		}
	}
	return(sort { $a->name cmp $b->name } @ret);
}

sub methods
{
	my $self=shift;
	my @ret;
	foreach my $method (sort keys(%{$self->{DATA}{methods}})) {
		if(defined $self->{DATA}{methods}{$method}{name}) {
			my $newmethod=$self->method($method);
			push @ret,$newmethod if defined $newmethod;
		}
	}
	return(sort { $a->name cmp $b->name } @ret);
}

sub superclass
{
	my $self=shift;
	return $self->{DATA}{superclass};
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::CIM::Instance - Provides access to instances in a L<DMTF::CIM> model


=head1 VERSION

This document describes DMTF::CIM::Instance version 0.04


=head1 SYNOPSIS

  use DMTF::CIM::WSMan;
  my $cim=DMTF::CIM::WSMan->new();

  my $instance = $cim->get('wsman.wbem://host:623/interop:CIM_ManagedElement.InstanceID=1');

  print $instance->class
  print ":$instance->superclass" if(defined $instance->superclass);
  print "\n";
  foreach my $prop ( $instance->defined_properties ) {
      print "$prop: ",$prop->value,"\n";
  }


=head1 DESCRIPTION

This class is returned by and passed into the various "connector" DMTF::CIM
modules such as DMTF::CIM::WSMan.  It is not expected to be used by itself.

=head1 INTERFACE 

The returned object behaves as described in the "OBJECTS" section of L<DMTF::CIM>
for non-valued objects.

=head2 METHODS

=over

=item C<< uri ( I<new_uri> ) >>

Returns or sets the untyped WBEM URI as defined in 
L<DSP0207|http://www.dmtf.org/sites/default/files/standards/documents/DSP0207_1.0.0.pdf>.

=item C<< class >>

Returns the class of the instance.

=item C<< superclass >>

Returns the parent class of the instance or undef is it is a top-level class.

=item C<< defined_properties >>

Returns a LIST of all properties which have a non-NULL value in the current instance.

=item C<< all_properties >>

Returns a LIST of B<all> properties in the current instance (including ones with a NULL value).

=item C<< is_association >>

Returns a true value if the instance class is an assocation class.

=item C<< property ( I<name> ) >>

Returns a L<DMTF::CIM::Instance::Property> object representing the specified
property name in the instance.

=item C<< methods >>

Returns a LIST of all methods in the current instance.

=item C<< method ( I<name> ) >>

Returns a L<DMTF::CIM::Instance::Method> object representing the specified
property name in the instance.

=back


=head1 DIAGNOSTICS

This class carp()s and returns undef (or empty list) on all errors.

=head1 CONFIGURATION AND ENVIRONMENT

DMTF::CIM::Instance requires no configuration files or environment variables.

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
