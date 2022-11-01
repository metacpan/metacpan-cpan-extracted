package CryptoTron::JsonHttp;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(
    encode
    HTTP_Request encode
    %SERVICES
    $API_URL
);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.07';

# Load the required Perl modules or packages.
use JSON::PP;
use URI;
use LWP::UserAgent;

# Set api url and api path.
our $API_URL = 'https://api.trongrid.io';

# Define the hash with the services.
our %SERVICES = (
    'GetNextMaintenanceTime' => ['/wallet/getnextmaintenancetime', 'GET'],
    'GetAccountResource'     => ['/wallet/getaccountresource',     'POST'],
    'GetAccount'             => ['/walletsolidity/getaccount',     'POST'],
    'GetReward'              => ['/wallet/getReward',              'POST'],
    'BroadcastTransaction'   => ['/wallet/broadcasttransaction',   'POST'],
    'WithdrawBalance'        => ['/wallet/withdrawbalance',        'POST'],
    'GetAccountBalance'      => ['/wallet/getaccountbalance',      'POST'],
    'GetAccountNet'          => ['/wallet/getaccountnet',          'POST'],
    'GetAccountResource'     => ['/wallet/getaccountresource',     'POST']
);

# ---------------------------------------------------------------------------- #
# Function encode()                                                            #
#                                                                              #
# Description:                                                                 # 
# The subroutine is encoding the given content using the module JSON::PP.      #
#                                                                              #
# @argument $content  Response content  (scalar)                               #
# @returns  $encoded  Encoded content   (scalar)                               #
# ---------------------------------------------------------------------------- #
sub encode {
    # Assign the argument to the local variable.
    my $content = $_[0];
    # Set up the options for the Perl module.
    my $json = 'JSON::PP'->new->pretty;
    # Encode content of the response.
    my $encoded = $json->encode($content);
    # Return encoded and decoded data.
    return $encoded;
};

# ---------------------------------------------------------------------------- #
# Function HTTP_Request()                                                      # 
#                                                                              #
# Description:                                                                 #
# The subroutine is using the HTTP methods GET or POST to send a request to a  #
# known servive url of the Full-Node HTTP API. On success a content in form of #
# JSON data is returned.                                                       #
#                                                                              #
# @argument $service_url  Service url       (scalar)                           #
# @return   $content      Response content  (scalar)                           #
# ---------------------------------------------------------------------------- #
sub HTTP_Request {
    # Assign the subroutine arguments to the local variables.
    my ($service_url, $method, $payload) = @_;
    # Initialise the local variables.
    my $content = "";
    my $response = "";
    my $errcode = "";
    my $errmsg = "";
    # Set the header for the request.
    my $header = [Accept => 'application/json',
                  Content_Type => 'application/json'];
    # Create a new uri object from the service url.
    my $uri = URI->new($service_url);
    # Create a new user agent object.
    my $ua = LWP::UserAgent->new;
    # Get the response from the uri based on the given HTTP method.
    if ($method eq 'POST') {
        $response = $ua->post($uri, $header, Content => $payload);
    } elsif ($method eq 'GET') {
        $response = $ua->get($uri, $header, Content => $payload);
    };
    # Check success of operation.
    if ($response->is_success) {
        # Get the content from the response.
        $content = $response->content;
        $errcode = $response->code;
        $errmsg = $response->message;
    } else {
        # Get error code and error message.
        $errcode = $response->code;
        $errmsg = $response->message;
        $content = "";
    };
    # Return content, error code, error message and service url.
    return ($content, $errcode, $errmsg, $service_url);
};

1;

__END__

=head1 NAME

CryptoTron::JsonHttp - Perl extension for use with the blockchain of the crypto coin Tron.

=head1 SYNOPSIS

None

=head1 DESCRIPTION

None

=head1 SEE ALSO

Try::Catch

POSIX

URI

LWP::UserAgent

JSON::PP

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
