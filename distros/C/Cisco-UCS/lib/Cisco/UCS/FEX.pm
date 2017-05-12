package Cisco::UCS::FEX;

use warnings;
use strict;

use Carp qw(croak);
use Scalar::Util qw(weaken);

our $VERSION = '0.51';

our @ATTRIBUTES	= qw(discovery dn id model operability perf power presence 
revision serial side thermal vendor voltage);

our %ATTRIBUTES = (
	chassis_id	=> 'chassisId',
	config_state	=> 'configState',
	oper_state	=> 'operState',
	peer_status	=> 'peerCommStatus',
	switch_id	=> 'switchId',
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
				)->{outConfig}->{equipmentIOCard}};
            
        while ( my ($k, $v) = each %attr ) { $self->{$k} = $v }
                    
        return $self;
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::FEX - Class for operations with a Cisco UCS FEX.

=head1 SYNOPSIS

    my @fexs = $ucs->chassis(2)->get_fexs;

    print $fexs[0]->thermal;

    print $ucs->chassis(1)->fex(1)->model;

=head1 DECRIPTION

Cisco::UCS::FEX is a class providing operations with a Cisco UCS FEX.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::FEX object is created automatically by method calls to a 
L<Cisco::UCS::Chassis> object.

=head1 METHODS

=head3 id

Returns the id of the FEX.

=head3 dn

Returns the distinguished name of the FEX.

=head3 model

returns the model number of the FEX.

=head3 vendor

Returns the vendor name of the FEX.

=head3 revision

returns the revision number of the FEX.

=head3 discovery

Returns the discovery status of the FEX.

=head3 operability 

Returns the operability state of the FEX.

=head3 perf

Returns the performance status of the FEX.

=head3 power

Returns the power status of the FEX.

=head3 presence

Returns the presence status of the FEX.

=head3 serial

returns the serial number of the FEX.

=head3 side

Returns the side (right or left) of the FEX's physical location in the chassis.

=head3 thermal

Returns the thermal status of the FEX.

=head3 voltage

Returns the voltage status of the FEX.

=head3 chassis_id

Returns the ID of the chassis in which the FEX is installed.

=head3 config_state

Returns the configuration state of the FEX.

=head3 oper_state

Returns the operational state of the FEX.

=head3 peer_status

Returns the peer communication status of the FEX.

=head3 switch_id

Returns the ID (A or B) of the Fabric Interconnect to which the FEX is 
physically attached.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Some methods may return undefined, empty or not yet implemented values.  This 
is dependent on the software and firmware revision level of UCSM and 
components of the UCS cluster.  This is not a bug but is a limitation of UCSM.

Please report any bugs or feature requests to 
C<bug-cisco-ucs-fex at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-FEX>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as 
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::FEX

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-FEX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-FEX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-FEX>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-FEX/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
