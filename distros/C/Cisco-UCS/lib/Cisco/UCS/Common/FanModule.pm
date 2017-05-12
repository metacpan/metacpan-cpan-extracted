package Cisco::UCS::Common::FanModule;

use warnings;
use strict;

use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our @ATTRIBUTES = qw(dn id model operability power presence revision serial 
thermal tray vendor voltage);

our %ATTRIBUTES = ( 
	performance	=> 'perf',
	oper_state	=> 'operState'
);  

{
	no strict 'refs';

	while ( my ( $pseudo, $attribute ) = each %ATTRIBUTES ) { 
		*{ __PACKAGE__ . '::' . $pseudo } = sub {
			my $self = shift;
			return $self->{$attribute}
		}   
	}   

        foreach my $attribute ( @ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $attribute } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }

}

sub new {
	my ( $class, %args ) = @_;

	my $self = {};
	bless $self, $class;

	defined $args{dn}
		? $self->{dn} = $args{dn}
		: croak 'dn not defined';

	defined $args{ucs}
		? weaken($self->{ucs} = $args{ucs})
		: croak 'ucs not defined';

	my %attr = %{ $self->{ucs}->resolve_dn(
				dn => $self->{dn}
			)->{outConfig}->{equipmentFanModule} };

	while ( my ( $k, $v ) = each %attr ) { $self->{$k} = $v }

	return $self;
}

sub fan {
        my ( $self, $id ) = @_; 

        return ( defined $self->{fan}->{$id} 
			? $self->{fan}->{$id}
			: $self->get_fan($id) 
	)
}

sub get_fan {
	my ( $self, $id ) = @_;

	return $self->get_fans( $id )
}

sub get_fans {
	my ( $self, $id ) = @_;

	return $self->{ucs}->_get_child_objects(
				id	=> $id,
				type	=> 'equipmentFan',
				class	=> 'Cisco::UCS::Common::Fan', 
				attr	=> 'fan',
				self	=> $self
	)
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::Common::FanModule - Class for operations with a Cisco UCS Fan 
Module.

=cut

=head1 SYNOPSIS

  print "Fan module " . $ucs->chassis(1)->fan_module(1)->id .
	" thermal: " . $ucs->chassis(1)->fan_module(1)->thermal . "\n";

  my @fans = $ucs->chassis(1)->fan_module(1)->get_fans;

=head1 DESCRIPTION

Cisco::UCS::Common::FanModule is a class providing operations with a Cisco UCS 
Fan Module.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Common::FanModule is created automatically via method calls to a 
L<Cisco::UCS::Chassis> object like I<fan_module>.

=head1 METHODS

=head3 fan ($id)

  my $fan = $ucs->chassis(1)->fan_module(1)->fan(2);

Returns a L<Cisco::UCS::Common::Fan> object for the specified fan module 
identified by the provided fan ID.  

Note that the default behaviour for this method is to return a cached object 
retrieved by a previous lookup if one is available.  Please see the 
B<Caching Methods> section in B<NOTES> for further information.

=head3 get_fan ($id)

  my $fan = $ucs->chassis(2)->fan_module(1)->get_fan(1);

Returns a L<Cisco::UCS::Common::Fan> object identified by the given fan ID.

This method always queries the UCSM for information on the specified fan - 
contrast this with the behaviour of the analogous caching method I<fan()>.

=head3 get_fans

  my @fans = $ucs->get_chassis(2)->fan_module(1)->get_fans;

Returns an array of L<Cisco::UCS::Common::Fan> objects.  This is a non-caching 
method.

=head3 dn

Returns the distinguished name of the L<Cisco::UCS::Common::FanModule> in the 
Cisco UCS management hierarchy.

=head3 id

Returns the numerical ID of the fan module.

=head3 model

Returns the model number of the fan module.

=head3 operability

Returns the operability status of the fan module.

=head3 oper_state

Returns the operational state of the fan module.

=head3 performance

Returns the performance status of the fan module.

=head3 power

Returns the power status of the fan module.

=head3 presence

Returns the presence status of the fan module.

=head3 revision

Returns the revision number of the fan module object.

=head3 serial

Returns the serial number of the fan module.

=head3 thermal

Returns the thermal status of the fan module.

=head3 tray

Returns the tray identifier in which the fan module is installed.

=head3 vendor

Returns the vendor information for the fan module.

=head3 voltage

Returns the voltage status of the fan module.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-common-fanmodule at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Chassis-FanModule>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Chassis::FanModule

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Chassis-FanModule>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Chassis-FanModule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Chassis-FanModule>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Chassis-FanModule/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

