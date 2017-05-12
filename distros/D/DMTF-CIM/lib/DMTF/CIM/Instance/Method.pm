package DMTF::CIM::Instance::Method;

use warnings;
use strict;

use version;
our $VERSION = qv('0.04');
require DMTF::CIM::_model;
use DMTF::CIM::Instance::Method::Parameter;
use Carp;

our @ISA=qw(DMTF::CIM::_valued);

# Module implementation here
sub new
{
	my $class=shift;
	my %args=@_;
	my $result;
	my $self=DMTF::CIM::_valued::new($class, parent=>$args{parent},data=>$args{method},value=>\$result);
	$self->{VALUES}=$args{values} || {};
	$self->{PARAMETERS}={};
	return($self);
}

sub parameter
{
	my $self=shift;
	my $param=shift;

	if(!defined $param) {
		carp "No parameter name specified";
		return;
	}
	my $lcp=lc($param);
	return $self->{PARAMETERS}{$lcp} if(defined $self->{PARAMETERS}{$lcp});
	my $paramref=$self->{DATA}{parameters}{$lcp};
	if(!defined $paramref) {
		carp "Parameter $param not specified in model";
		return;
	}
	$self->{PARAMETERS}{$lcp}=DMTF::CIM::Instance::Method::Parameter->new(parent=>$self, parameter=>$paramref, value=>\$self->{VALUES}{$paramref->{name}});
	return $self->{PARAMETERS}{$lcp};
}

sub in_params
{
	my $self=shift;
	my @ret;

	foreach my $key (keys %{$self->{DATA}{parameters}}) {
		my $param=$self->parameter($key);
		next unless defined $param;
		push @ret,$param if $param->qualifier('in') eq 'true';
	}
	return @ret;
}

sub out_params
{
	my $self=shift;
	my @ret;

	foreach my $key (keys %{$self->{DATA}{parameters}}) {
		my $param=$self->parameter($key);
		next unless defined $param;
		push @ret,$param if $param->qualifier('out') eq 'true';
	}
	return @ret;
}

sub parameters
{
	my $self=shift;
	my @ret;

	foreach my $key (keys %{$self->{DATA}{parameters}}) {
		my $param=$self->parameter($key);
		push @ret, $param if defined $param;
	}
	return @ret;
}

sub clear_parameters
{
	my $self=shift;
	my $result;
	$self->{PARAMETERS}={};
	$self->{VALUES}={};
	$self->{VALUE}=\$result;
}

sub invoke
{
	my $self=shift;
	my $dad=$self->parent;
	if(!defined $dad) {
		carp "Unable to get parent instance";
		return;
	}
	if(!defined $dad->uri) {
		carp "Parent instances does not hve a URI";
		return;
	}
	my $grandma=$dad->parent;
	if(!defined $grandma) {
		carp "Unable to get grandparent model";
		return;
	}

	my $params={};
	foreach my $param ($self->in_params) {
		if($param->is_array) {
			my $rv=$param->raw_value;
			if(defined $rv) {
				my $vals=[];
				foreach my $value ($param->raw_value) {
					push @$vals,$value if defined $value;
				}
				$params->{$param->name}=$vals;
			}
		}
		else {
			my $rv=$param->raw_value;
			$params->{$param->name}=$rv if defined $rv;
		}
	}
	my $result=$grandma->InvokeMethod(uri=>$dad->uri,method=>$self->name,params=>$params);
	return unless defined $result;
	foreach my $out (keys %$result) {
		if($out eq 'ReturnValue') {
			$self->raw_value($result->{$out});
		}
		else {
			$self->parameter($out)->raw_value($result->{$out});
		}
	}
	return $result->{ReturnValue};
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::CIM::Instance::Method - Provides access to methods from a L<DMTF::CIM::Instance>


=head1 VERSION

This document describes DMTF::CIM::Instance::Method version 0.04


=head1 SYNOPSIS

  use DMTF::CIM::WSMan;
  my $cim=DMTF::CIM::WSMan->new();

  my $instance = $cim->get('wsman.wbem://host:623/interop:CIM_ManagedElement.InstanceID=1');

  $instance->method->Invoke(param=>value);

=head1 DESCRIPTION

This class is returned by the method method of L<DMTF::CIM::Instance::Method> 
It is not expected to be used by itself.

=head1 INTERFACE 

The returned object behaves as described in the "OBJECTS" section of L<DMTF::CIM>
for valued objects.  The return value is the value of the method.

=head2 METHODS

=over

=item C<< new ( [ method=>I<method_def> ] ) >>

Creates a new property with the CIM property description I<property_def>
and a value stored at I<valueref>.

=item C<< parameter( I<name> ) >>

Returns a valued object as described in L<DMTF::CIM> for the named parameter.

=item C<< parameters >>

Returns a list of all in and out parameters for the method.

=item C<< in_params >>

Returns a list of all input parameters for the method.

=item C<< out_params >>

Returns a list of all output parameters for the method.

=item C<< clear_parameters >>

Removes all values from all the associated parameters.

=item C<< invoke >>

Invokes the method with the currently set parameter values and sets the value
of the method object to be the return value.

=back

Note that some parameters may be present in both in_params and out_params.

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
