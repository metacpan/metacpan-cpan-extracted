package Cisco::UCS::Common::Fan;

use warnings;
use strict;

use Scalar::Util	qw(weaken);
use Carp		qw(croak);

our $VERSION = '0.51';

our @ATTRIBUTES = qw(dn id model operability power presence revision serial 
thermal tray vendor voltage);

our %ATTRIBUTES	= (
	performance	=> 'perf',
	oper_state	=> 'operState'
);

{
	no strict 'refs';

	while ( my ($pseudo, $attribute) = each %ATTRIBUTES ) { 
		*{ __PACKAGE__ . '::' . $pseudo } = sub {
			my $self = shift;
			return $self->{$attribute}
		}   
	}   
	
	foreach my $attribute (@ATTRIBUTES) {
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

	defined $args{id}
		? $self->{id} = $args{id}
		: croak 'id not defined';

	defined $args{ucs}
		? weaken( $self->{ucs} = $args{ucs} )
		: croak 'ucs not defined';

	my %attr = %{ $self->{ucs}->resolve_dn(
						dn => $self->{dn}
					)
			};

	%attr = %{ exists $attr{outConfig}{equipmentFan} 
			? $attr{outConfig}{equipmentFan} 
			: $attr{outConfig}{equipmentFanModule} 
	};

	while ( my ($k, $v ) = each %attr) { $self->{$k} = $v }

	return $self;
}

1;

__END__

=head1 NAME

Cisco::UCS::Common::Fan - Class for operations with a Cisco UCS fan.

=cut

=head1 SYNOPSIS

    print 'Thermal: '. $ucs->chassis(1)->fan_module(2)->fan(1)->thermal ."\n";

=head1 DESCRIPTION

Cisco::UCS::Common::Fan is a class providing operations with a Cisco UCS fan.

Note that you are not supposed to call the constructor yourself, rather a 
Cisco::UCS::Common::Fan object is created automatically by method calls to 
other L<Cisco::UCS> objects like L<Cisco::UCS::Chassis::FanModule>.

=head1 METHODS

=head3 dn

Returns the distinguished name of the Cisco::UCS::Common::Fan object in the 
Cisco UCS management hierarchy.

=head3 id

Returns the numerical identifier of the fan object.

=head3 model

Returns the model number of the specified fan object.

=head3 serial

Returns the serial number of the fan object.

=head3 operability

Returns the operability status of the specified fan.

=head3 perf

Returns the performance status of the specified fan.

=head3 performance

Returns the performance information of the specified fan.

=head3 power

Returns the power status of the specified fan.

=head3 presence

Returns the presence status of the specified fan.

=head3 oper_state

Returns the operational state of the specified fan.

=head3 revision

Returns the revision information of the specified fan.

=head3 thermal

Returns the thermal status of the specified fan.

=head3 tray

Returns the tray identifier for the specified fan.

=head3 vendor

Returns the vendor information for the specified fan.

=head3 voltage

Returns the voltage status for the specified fan.

=cut


=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-chassis-fan at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Chassis-Fan>.  I 
will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Common::Fan

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Chassis-Fan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Chassis-Fan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Chassis-Fan>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Chassis-Fan/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

