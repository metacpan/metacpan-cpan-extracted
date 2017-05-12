package Cisco::UCS::Chassis::PSU;

use warnings;
use strict;

use Carp qw(croak);
use Scalar::Util qw(weaken);
use Cisco::UCS::Chassis::PSU::Stats;

our $VERSION = '0.51';

our %ATTRIBUTES	= (
	id 		=> 'id',
	model 		=> 'model',
	operability 	=> 'operability',
	operational	=> 'operState',
	performance	=> 'perf',
	power 		=> 'power',
	presence 	=> 'presence',
	revision 	=> 'revision',
	serial 		=> 'serial',
	thermal 	=> 'thermal',
	vendor 		=> 'vendor',
	voltage		=> 'voltage',
);

{
        no strict 'refs';

        while ( my ($pseudo, $attribute) = each %ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $pseudo } = sub { 
			return $_[0]->{$attribute} 
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
			)->{outConfig}->{equipmentPsu}};
        
        while ( my ($k, $v) = each %attr ) { $self->{$k} = $v }
                
        return $self;
}

sub stats {
        my $self = shift;
        return Cisco::UCS::Chassis::PSU::Stats->new(
                $self->{ucs}->resolve_dn( 
				dn => "$self->{dn}/stats" 
			)->{outConfig}->{equipmentPsuStats} )
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::Common::PSU - Class for operations with a Cisco UCS PSU.

=head1 SYNOPSIS

    foreach my $psu (sort $ucs->chassis(1)->get_psus) {
      print 'PSU ' . $psu->id . ' voltage: ' . $psu->voltage . "\n" 
    }

    # PSU 1 voltage: ok
    # PSU 2 voltage: ok
    # PSU 3 voltage: ok
    # PSU 4 voltage: ok

=head1 DESCRIPTION

Cisco::UCS::Common::PSU is a class providing common operations with a Cisco 
UCS PSU.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Common::PSU object is created for you automatically by query 
methods in other classes like L<Cisco::UCS::Chassis>.

=head1 METHODS

=head3 id

Returns the ID of the PSU.

=head3 dn

Returns the distinguished name of the PSU.

=head3 serial

Returns the serial number of the PSU.

=head3 model

Returns the model number of the PSU.

=head3 revision

Returns the hardware revision number of the PSU.

=head3 vendor

Returns the vendor name of the PSU.

=head3 presence

Returns the presence status of the PSU.

=head3 operability

Returns the operability status of the PSU.

=head3 voltage

Returns the voltage status of the PSU.

=head3 power

Returns the power status of the PSU.

=head3 thermal

Returns the thermal status of the PSU.

=head3 operational

Returns the operational status of the PSU.

=head3 performance

Returns the performance status of the PSU.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Some methods may return undefined, empty or not yet implemented values.  This 
is dependent on the software and firmware revision level of UCSM and 
components of the UCS cluster.  This is not a bug but is a limitation of UCSM.

Please report any bugs or feature requests to 
C<bug-cisco-ucs-common-psu at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Common-PSU>.  I 
will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Common::PSU

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Common-PSU>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Common-PSU>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Common-PSU>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Common-PSU/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
