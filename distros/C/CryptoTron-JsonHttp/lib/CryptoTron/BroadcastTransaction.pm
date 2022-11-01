package CryptoTron::BroadcastTransaction;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(BroadcastTransaction);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.02';

# Load the required Perl modules or packages.
use URI;
use LWP::UserAgent;
use JSON::PP;

# Set the variable $JSON.
our $JSON = 'JSON::PP'->new->pretty;

# Define the global variables.
our($HEADER, $SERVICE_URL);

# Set api url and api path.
our $API_URL = 'https://api.trongrid.io';
our $API_PATH = '/wallet/broadcasttransaction';

# Set the request header.
$HEADER = [Accept => 'application/json',
           Content_Type => 'application/json'];

# Assemble the service url.
$SERVICE_URL = $API_URL.$API_PATH;

# ---------------------------------------------------------------------------- #
# Subroutine encode()                                                          #
#                                                                              #
# Description:                                                                 # 
# The subroutine is first decoding and second encoding the retrieved content   #
# from the HTTP response using the method POST.                                #
#                                                                              #
# @argument $content      Response content  (scalar)                           #
# @returns  $json_encode  Encoded content   (scalar)                           #
# ---------------------------------------------------------------------------- #
sub encode {
    # Assign the argument to the local variable.
    my $content = $_[0];
    # Decode the content from the response.
    my $json_decode = $json->decode($content);
    # Encode the decoded content from the response.
    my $json_encode = $json->encode($json_decode);
    # Return the encoded content.
    return $json_encode;
};

# ---------------------------------------------------------------------------- #
# Subroutine get_response()                                                    # 
#                                                                              #
# Description:                                                                 #
# The subroutine is using the HTTP method POST to retrieve the response from   #
# the given service url.                                                       #
#                                                                              #
# @argument $service_url  Service URL       (scalar)                           #
# @return   $content      Response content  (scalar)                           #
# ---------------------------------------------------------------------------- #
sub get_response {
    # Assign the argument to the local variable.
    my $payload = $_[0];
    my $service_url = $_[1];
    # Declare the variable $content.
    my $content = "";
    # Create a new uri object.
    #my $uri = URI->new($SERVICE_URL_0);
    my $uri = URI->new($service_url);
    # Create a new user agent object.
    my $ua = LWP::UserAgent->new;
    # Get the response from the uri.
    my $response = $ua->post($uri, $HEADER, Content => $payload);
    # Check success of operation.
    if ($response->is_success) {
        # Get the content from the response.
        $content = $response->content;
    };
    # Return the content.
    return $content;
};

# ---------------------------------------------------------------------------- #
# Subroutine BroadcastTransaction()                                            #
# ---------------------------------------------------------------------------- #
sub BroadcastTransaction {
    # Assign the subroutine arguments to the local variables.
    my $signature = $_[0];
    my $raw_data_hex = $_[1];
    my $raw_data = $_[2];
    # Create the payload.
    my $payload = "\{\"raw_data\":$raw_data,\"raw_data_hex\":\"$raw_data_hex\",\"signature\":[\"$signature\"]\}";
    # Get the content from the response.
    my $content = get_response($payload, $SERVICE_URL);
    # Return the content.
    return $content;
};

1;

__END__

=head1 NAME

CryptoTron::BroadcastTransaction - Perl extension for use with the blockchain of the crypto coin Tron.

=head1 SYNOPSIS

None

=head1 DESCRIPTION

None

=head1 SEE ALSO

Try::Catch

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
