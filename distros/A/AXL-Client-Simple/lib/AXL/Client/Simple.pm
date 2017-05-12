package AXL::Client::Simple;
use Moose;

with qw/
    AXL::Client::Simple::Role::SOAP
    AXL::Client::Simple::Role::getPhone
    AXL::Client::Simple::Role::getDeviceProfile
    AXL::Client::Simple::Role::getLine
/;
use AXL::Client::Simple::Phone;
use URI::Escape ();
use Carp;

our $VERSION = '0.02';
$VERSION = eval $VERSION; # numify for warning-free dev releases

has username => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has server => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub get_phone {
    my ($self, $phone_name) = @_;

    my $device = $self->getPhone->(phoneName => $phone_name);
    if (exists $device->{'Fault'}) {
        my $f = $device->{'Fault'}->{'faultstring'};
        croak "Fault status returned from server in get_phone: $f\n";
    }

    return AXL::Client::Simple::Phone->new({
        client => $self,
        stash  => $device->{'parameters'}->{'return'}->{'device'},
    });
}

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # collect AXL password from environment as last resort
    $params->{password} ||= $ENV{AXL_PASS};

    # URI escape the username and password
    $params->{username} ||= '';
    $params->{username} = URI::Escape::uri_escape($params->{username});
    $params->{password} = URI::Escape::uri_escape($params->{password});

    return $params;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 NAME

AXL::Client::Simple - Cisco Unified Communications XML API

=head1 VERSION

This document refers to version 0.02 of AXL::Client::Simple

=head1 SYNOPSIS

Set up your CUCM AXL client:

 use AXL::Client::Simple;
 
 my $cucm = AXL::Client::Simple->new({
     server      => 'call-manager-server.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{AXL_PASS}
 });

Then perform simple queries on the Unified Communications server:

 my $device = $cucm->get_phone('SEP001122334455');
 
 my $lines = $device->lines;
 printf "this device has %s lines.\n", $lines->count;
 
 while ($lines->has_next) {
     my $l = $lines->next;
     print $l->alertingName, "\n";
     print $l->extn, "\n";
 }
 
 if ($device->has_active_em) {
     # extension mobility is active, so the lines are different
 
     my $profile = $device->currentProfile;
 
     my $profile_lines = $profile->lines;
     printf "this profile has %s lines.\n", $profile_lines->count;
 
     while ($profile_lines->has_next) {
         my $l = $profile_lines->next;
         print $l->alertingName, "\n";
         print $l->extn, "\n";
     }
 }

=head1 DESCRIPTION

This module acts as a client to the Cisco Unified Communications
Administrative XML interface (AXL). From here you can perform simple queries
to retrieve phone device details and in particular the lines active on a
device.

Although the API is presently very limited, it should be possible to add
access to additional device and line properties, although performing other AXL
calls is probably out of scope (hence the module being named Simple).

If the device is running Extension Mobility and a user is logged in, you can
also retrieve the line details from the current mobility profile active on the
handset.

=head1 METHODS

=head2 AXL::Client::Simple->new( \%arguments )

Instantiates a new AXL client. There won't be any connection to the server
until you call the device retrieval method C<get_phone>. Arguments are:

=over 4

=item C<< server => >> Fully Qualified Domain Name (required)

The host name of the CUCM server to which the module should connect. Note that
the port number 8443 and the path C</axl/> are automatically appended so you
need only provide the FQDN or IP address.

=item C<< username => >> String (required)

The account username under which the module will connect to CUCM. This value
will be URI encoded by the module.

=item C<< password => >> String OR via C<$ENV{AXL_PASS}> (required)

The password of the account under which the module will connect to CUCM.  This
value will be URI encoded by the module. You can also provide the password via
the C<AXL_PASS> environment variable.

=item C<< schema_path => >> String (optional)

A folder on your file system which contains the WSDL and Schema file which
describe the Administrative XML (AXL) interface. They are shipped with this
module so your providing this is optional.

=back

=head2 C<< $cucm->get_phone( <device-name> ) >>

Retrieves the L<AXL::Client::Simple::Phone> object which reveals a limited
number of phone properties and details on the active extensions on the
handset. See that linked manual page for more details.

=head1 REQUIREMENTS

=over 4

=item * L<Moose>

=item * L<MooseX::Iterator>

=item * L<XML::Compile::SOAP>

=item * L<XML::Compile::WSDL11>

=item * L<URI::Escape>

=item * L<File::ShareDir>

=back

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 COPYRIGHT & LICENSE

Copyright (c) University of Oxford 2010.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
