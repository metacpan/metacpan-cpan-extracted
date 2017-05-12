package Cisco::UCS::Chassis;

use warnings;
use strict;

use Cisco::UCS::FEX;
use Cisco::UCS::Common::FanModule;
use Cisco::UCS::Common::Fan;
use Cisco::UCS::Chassis::PSU;
use Cisco::UCS::Chassis::Stats;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use vars qw(@ISA);

@ISA = qw(Cisco::UCS);

our $VERSION = '0.51';

our %ATTRIBUTES = (
	adminState	=> 'admin_state',
	connPath	=> 'conn_path',
	connStatus	=> 'conn_status',
	dn		=> 'dn',
	id		=> 'id',
	managingInst	=> 'managing_instance',
	model		=> 'model',
	operState	=> 'oper_state',
	operability	=> 'operability',
	power		=> 'power',
	presence	=> 'presence',
	seepromOperState=> 'seeprom_oper_state',
	serial		=> 'serial',
	thermal		=> 'thermal',
	usrLbl		=> 'label',
	vendor		=> 'vendor',
);

{
        no strict 'refs';

        while ( my ($attribute, $pseudo) = each %ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $pseudo } = sub {
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
		? weaken($self->{ucs} = $args{ucs} )
		: croak 'ucs not defined';

	my %attr = %{$self->{ucs}->resolve_dn(
						dn => $self->{dn}
					)->{outConfig}->{equipmentChassis}};

	while ( my ($k, $v) = each %attr ) { $self->{$k} = $v }

	return $self;
}

sub blade {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{blade}->{$id}
			? $self->{blade}->{$id}
			: $self->get_blades( $id ) 
	)
}

sub get_blade {
	my ( $self, $id ) = @_;

	return (	
		$id	? $self->get_blades( $id ) 
			: undef 
	)
}

sub get_blades {
        my ( $self, $id ) = @_;

	return $self->_get_child_objects(
			id		=> $id,
			type		=> 'computeBlade', 
			class		=> 'Cisco::UCS::Blade', 
			attr		=> 'blade', 
			uid		=> 'slotId',
			class_filter	=> { 
					    classId   => 'computeBlade',
					    chassisId => $self->{id} 
					  } 
	)
}

sub fex {
	my ( $self, $id ) = @_;

	return ( 
		defined $self->{fex}->{$id} 
			? $self->{fex}->{$id}
			: $self->get_fexs( $id ) 
	)
}

sub get_fex {
	my ( $self, $id ) = @_;

	return ( 
		$id	? $self->get_fexs( $id ) 
			: undef 
	)
}

sub get_fexs {
	my ( $self, $id ) = @_;

	return $self->_get_child_objects(
		id	=> $id,
		type	=> 'equipmentIOCard',
		class	=> 'Cisco::UCS::FEX',
		attr	=> 'fex'
	)
}

sub fan_module {
	my ( $self, $id ) = @_;

	return (
		defined $self->{fan_module}->{$id} 
			? $self->{fan_module}->{$id}
			: $self->get_fan_module( $id ) 
	)
}

sub get_fan_module {
	my ( $self, $id ) = @_;

	return ( 
		$id	? $self->get_fan_modules( $id )
			: undef 
	)
}

sub get_fan_modules {
	my ( $self, $id ) = @_;

	return $self->_get_child_objects(
		id	=> $id,
		type	=> 'equipmentFanModule',
		class	=> 'Cisco::UCS::Common::FanModule',
		attr	=> 'fan_module'
	)
}

sub psu {
	my ( $self, $id ) = @_;

	return (
		defined $self->{psu}->{$id} 
			? $self->{psu}->{$id}
			: $self->get_psus( $id )
	)
}

sub get_psu {
        my ( $self, $id ) = @_;

        return $self->get_psu( $id )
}

sub get_psus {
	my ( $self, $id ) = @_;

	return $self->_get_child_objects(
		id	=> $id,
		type	=> 'equipmentPsu',
		class	=> 'Cisco::UCS::Chassis::PSU',
		attr	=> 'psu'
	)
}

sub stats {
        my $self = shift;

        return Cisco::UCS::Chassis::Stats->new( 
                $self->{ucs}->resolve_dn( 
			dn => "$self->{dn}/stats" 
		)->{outConfig}->{equipmentChassisStats} 
	)
}

1;

__END__

=head1 NAME

Cisco::UCS::Chassis - Class providing operations with a Cisco UCS Chassis

=head1 SYNOPSIS

        my $chassis = $ucs->chassis(1);

	print $chassis->serial;

	foreach my $chassis (sort $ucs->get_chassis) {
		print "Chassis: " . $chassis->id 
			. " - Serial: " . $chassis->serial . "\n";
	}

=head1 DESCRIPTION

Cisco::UCS::Chassis is a class providing operations with a Cisco UCS chassis.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Chassis is created automatically via calls to a L<Cisco::UCS> 
object like I<get_chassis> or I<chassis>.

=head2 METHODS

=head3 blade ( $id )

  my $blade = $ucs->chassis(1)->blade(2);

  print $blade->serial;

Returns a L<Cisco::UCS::Blade> object for the blade identified by the given 
slot ID.  This method takes a single mandatory argument - an integer value 
specifying the slot ID of the desired blade.

Note that the default behaviour of this method is to return a cached object 
retrieved in a previous lookup if one is available.  Please see the 
B<Caching Methods> section in B<NOTES> for further information.

=head3 get_blade ( $id )

  my $chassis = $ucs->chassis(3);

  my $blade = $chassis->get_blade(1);

  print "Blade " . $blade->id . " thermal is " . $blade->thermal 
		. ", power is " . $blade->power . "\n";

Returns a L<Cisco::UCS::Blade> object for the specified blade identified by 
the given slot ID.

This method always queries the UCSM for information on the specified blade - 
contrast this behaviour with the behaviour of the analogous caching method 
I<blade()>;

=head3 get_blades

  foreach my $blade ($ucs->chassis(1)->get_blades) {
    print $blade->serial . "\n"
  }

Returns an array of L<Cisco::UCS::Blade> objects.  This is a non-caching method.

=head3 fex ( $id )

  my $fex = $ucs->chassis(1)->fex(1);

  print $blade->serial;

Returns a L<Cisco::UCS::FEX> object for the blade identified by the given slot 
ID.  This method takes a single mandatory argument - an integer value 
specifying the slot ID of the desired FEX.

Note that the default behaviour of this method is to return a cached object 
retrieved in a previous lookup if one is available.  Please see the 
B<Caching Methods> section in B<NOTES> for further information.

=head3 get_fex ( $id )

  my $fex = $ucs->chassis(1)->fex(1);

  print $fex->serial;

Returns a L<Cisco::UCS::FEX> object for the FEX identified by the given slot 
ID.

This method always queries the UCSM for information - contrast this with the 
behaviour of the analagous caching method I<fex()>.

=head3 get_fexs

  my @fex = $ucs->chassis(1)->get_fexs;

Returns an array of L<Cisco::UCS::FEX> objects for the FEXs in the specified 
chassis.  This is a non-caching method.

=head3 fan_module ( $id )

  print $ucs->chassis(1)->fan_module(1)->thermal;

Returns a L<Cisco::UCS::Common::FanModule> object for the specified fan module.  
Note that the default behaviour of this method is to return a cached object as 
retrieved by a previous call to the UCSM if available.  See the 
B<Caching Method> section in B<NOTES> for further details.

=head3 get_fan_module ( $id )

  my $fm = $ucs->chassis(1)->get_fan_module(1);

Returns a L<Cisco::UCS::Common::FanModule> object for the specified fan module 
in the designated chassis.

This is a non-caching method and always queries the UCSM for information.

=head3 get_fan_modules

  my @fan_modules = $ucs->chassis(3)->get_fan_modules;

Returns an array of L<Cisco::UCS::Common::FanModules> for the specified 
chassis.  This is a non-caching method.

=head3 psu ( $id )

  my $psu = $ucs->chassis(1)->psu(2);

  print $psu->serial;

Returns a L<Cisco::UCS::Chassis::PSU> object for the chassis identified by the 
given PSU ID.  This method takes a single mandatory argument - an integer value 
specifying the ID of the desired PSU.

Note that the default behaviour of this method is to return a cached object 
retrieved in a previous lookup if one is available.  Please see the 
B<Caching Methods> section in B<NOTES> for further information.

=head3 get_psu ( $id )

  my $psu = $ucs->chassis(1)->get_psu(1);

Returns a L<Cisco::UCS::Chassis::PSU> object for the chassis identified by the 
given PSU ID. This method is non-caching and will always query the UCSM for 
information.

=head3 get_psus

  my @psus = $ucs->chassis(1)->get_psus;

Returns an array of L<Cisco::UCS::Chassis::PSU> objects for the given chassis.  
This method is non-caching.

=head3 stats

  print "Output power: ". $ucs->chassis(1)->stats->output_power ." W\n";

Return a L<Cisco::UCS::Chassis::Stats> object containing the current power 
statistics for the specified chassis.

=head3 admin_state

Returns the administrative state of the chassis.

=head3 conn_path

Returns the connection patrh status of the chassis.

=head3 conn_status

Returns the connection status of the chassis.

=head3 dn

Returns the distinguished name of the chassis in the UCS management heirarchy.

=head3 error

Returns the error status of the chassis.

=head3 id

Returns the numerical ID of the chassis.

=head3 label

Returns the user defined label of the chassis.

=head3 managing_instance

Returns the managing UCSM instance of the chassis (i.e. either A or B).

=head3 model

Returns the model number of the chassis.

=head3 oper_state

Returns the operational state of the chassis.

=head3 operability

Returns the operability status of the chassis.

=head3 power

Returns the power status of the chassis.

=head3 presence

Returns the presence status of the chassis.

=head3 seeprom_oper_state

Returns the SEEPROM operational status of the chassis.

=head3 serial

Returns the serial number of the chassis.

=head3 thermal

Returns the thermal status of the chassis.

=head3 vendor

Returns the vendor information for the chassis.


=head1 NOTES

=head2 Caching Methods

Several methods in the module return cached objects that have been previously 
retrieved by querying UCSM, this is done to improve the performance of methods 
where a cached copy is satisfactory for the intended purpose.  The trade off 
for the speed and lower resource requirement is that the cached copy is not 
guaranteed to be an up-to-date representation of the current state of the 
object.

As a matter of convention, all caching methods are named after the singular 
object (i.e. interconnect(), chassis()) whilst non-caching methods are named 
I<get_<object>>.  Non-caching methods will always query UCSM for the object,
as will requests for cached objects not present in cache.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-chassis at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Chassis>.  I will 
be notified, and then you'll automatically be notified of progress on your bug 
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Chassis

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Chassis>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Chassis>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Chassis>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Chassis/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
