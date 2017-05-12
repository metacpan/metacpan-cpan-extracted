package Cisco::UCS::Common::PSU;

use warnings;
use strict;

use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our @ATTRIBUTES	= qw(dn id model operability power presence revision serial 
thermal vendor voltage);

our %ATTRIBUTES	= (
	operational	=> 'operState',
	performance	=> 'perf'
);

#our 
#	'outputCurrentMin' => '10.000000',
#	'input210vAvg' => '239.000000',
#	'outputPowerAvg' => '120.869995',
#	'outputCurrent' => '10.000000',
#	'ambientTemp' => '26.000000',
#	'psuTemp1' => '0.000000',
#	'output12vAvg' => '12.087000',
#	'output12vMin' => '12.087000',
#	'outputCurrentMax' => '10.000000',
#	'output12v' => '12.087000',
#	'timeCollected' => '2012-10-19T13:07:33.952',
#	'outputCurrentAvg' => '10.000000',
#	'psuTemp2' => '0.000000',
#	'suspect' => 'no',
#	'thresholded' => '',
#	'ambientTempMin' => '26.000000',
#	'ambientTempMax' => '26.000000',
#	'output3v3Max' => '3.048000',
#	'output12vMax' => '12.087000',
#	'outputPowerMin' => '120.869995',
#	'input210v' => '239.000000',
#	'outputPowerMax' => '120.869995',
#	'input210vMin' => '239.000000',
#	'ambientTempAvg' => '26.000000',
#	'outputPower' => '120.869995',
#	'output3v3Avg' => '3.048000',
#	'intervals' => '58982460',
#	'output3v3' => '3.048000',
#	'update' => '131073',
#	'dn' => 'sys/chassis-1/psu-1/stats',
#	'input210vMax' => '239.000000',
#	'output3v3Min' => '3.048000'



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
				)->{outConfig}->{equipmentPsu} };
        
        while ( my ($k, $v) = each %attr ) { $self->{$k} = $v }
                
        return $self;
}

{
        no strict 'refs';

        while ( my ( $pseudo, $attribute ) = each %ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $pseudo } = sub { 
			return $_[0]->{$attribute} 
		}
        }

        foreach my $attribute (@ATTRIBUTES) {
                *{ __PACKAGE__ . '::' . $attribute } = sub { 
			return $_[0]->{$attribute} 
		}
        }
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

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
