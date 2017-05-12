# ============================================================================
package Business::UPS::Tracking::Commandline;
# ============================================================================
use utf8;
use 5.0100;

use Moose;
extends qw(Business::UPS::Tracking::Request);
with qw(MooseX::Getopt Business::UPS::Tracking::Role::Base);

=encoding utf8

=head1 NAME

Business::UPS::Tracking::Commandline - Commandline interface to UPS tracking

=head1 SYNOPSIS

  my $commandline = Business::UPS::Tracking::Commandline->new_with_options;
  # Params are taken from @ARGV
  $commandline->execute; 

=head1 DESCRIPTION

This class allows Business::UPS::Tracking being called from a commandline
script using L<MooseX::Getopt>. (See L<ups_tracking>)

=head1 ACCESSORS

=head2 Inherited

All accessors from L<Business::UPS::Tracking::Request>

=head2 verbose

Be verbose

=head2 AccessLicenseNumber

UPS tracking service access license number

=head2 UserId

UPS account username

=head2 Password

UPS account password

=head2 config

Optionally you can retrieve all or some UPS webservice credentials from a
configuration file. This accessor holds the path to this file.
Defaults to C<~/.ups_tracking>

Example configuration file:

 <?xml version="1.0"?>
 <UPS_tracking_webservice_config>
    <AccessLicenseNumber>1CFFED5A5E91B17</AccessLicenseNumber>
    <UserId>myupsuser</UserId>
    <Password>secret</Password>
 </UPS_tracking_webservice_config>

=head1 METHODS

=head3 execute

 $commandline->execute;

Performs a UPS webservice query/request.

=cut

has 'tracking' => (
    is          => 'rw',
    required    => 0,
    isa         => 'Business::UPS::Tracking',
    traits      => [ 'NoGetopt' ],
    lazy_build  => 1,
);

has 'verbose' => (
    is          => 'rw',
    isa         => 'Bool',
    documentation   => 'Be verbose',
);

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'Business::UPS::Tracking::Type::TrackingNumber' => '=s',
    'Business::UPS::Tracking::Type::CountryCode'    => '=s',
);

__PACKAGE__->meta->make_immutable;

sub execute {
    my $self = shift;
    
    my $response = $self->run();
    
    my $count = 1;
    
    foreach my $shipment (@{$response->shipment}) {
        say ".============================================================================.";
        say "| Shipment $count                                                                 |";
        say $shipment->printall->draw;
        say "";
        if ($self->verbose) {
            say $shipment->xml->toString(1);
        }
        $count ++;
    }
    
    return;
}

sub _build_tracking {
    my ($self) = @_;
    
    my %params = ();
    foreach my $field (qw(AccessLicenseNumber UserId Password)) {
        my $predicate = '_has_'.$field;
        if ($self->$predicate) {
            $params{$field} = $self->$field;
        }
    }
    
    return Business::UPS::Tracking->new(\%params);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
