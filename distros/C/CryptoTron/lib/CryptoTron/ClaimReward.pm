package CryptoTron::ClaimReward;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(ClaimReward
                 TransactionBuilder
                 BroadcastTransaction
                 parse_txID
                 parse_raw_data
                 parse_raw_data_hex
                 sign
);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.09';

# Load the required Perl modules or packages.
use URI;
use LWP::UserAgent;
use JSON::PP;

# Use Inline Python module to define a function.
use Inline Python => <<'END_OF_PYTHON_CODE';

# Import the Python modules.
#import sys
from eth_account import Account

# Define the Python function sign().
def sign_txID(txID, privKey):
    # txID = txID.decode()
    # privKey = privKey.decode()
    sign_tx = Account.signHash(txID, privKey)
    sign_eth = sign_tx['signature']
    sign_hex = sign_eth.hex()[2:]
    return sign_hex

END_OF_PYTHON_CODE

# Create alias.
*sign = \&sign_txID;

# Define the global variables.
our($HEADER, $SERVICE_URL_PRE, $SERVICE_URL_POST);

# Set api url and api path.
our $API_URL = 'https://api.trongrid.io';
our $API_PATH_PRE = '/wallet/withdrawbalance';
our $API_PATH_POST = '/wallet/broadcasttransaction';

# Set the request header.
$HEADER = [Accept => 'application/json',
           Content_Type => 'application/json'];

# Assemble the service url.
$SERVICE_URL_PRE = $API_URL.$API_PATH_PRE;
$SERVICE_URL_POST = $API_URL.$API_PATH_POST;

# ---------------------------------------------------------------------------- #
# Subroutine encode()                                                          #
#                                                                              #
# Description:                                                                 # 
# The subroutine is first decoding and second encoding the retrieved content   #
# from the HTTP response using the method POST.                                #
#                                                                              #
# @argument $content      Response content  (scalar)                           #
# @return   $json_encode  Encoded content   (scalar)                           #
# ---------------------------------------------------------------------------- #
sub encode {
    # Assign the argument to the local variable.
    my $content = $_[0];
    # Set up the options for the Perl module JSON::PP.
    my $json = 'JSON::PP'->new->pretty;
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
    # Assign the subroutine arguments to the local variables.
    my $payload = $_[0];
    my $service_url = $_[1];
    # Declare the variable $content.
    my $content = "";
    # Create a new uri object.
    my $uri = URI->new($service_url);
    # Create a new user agent object.
    my $ua = LWP::UserAgent->new;
    # Get the response from the uri.
    my $response = $ua->post($uri, $HEADER, Content => $payload);
    # Check the success of the operation.
    if ($response->is_success) {
        # Get the content from the response.
        $content = $response->content;
    };
    # Return the content.
    return $content;
};

# ---------------------------------------------------------------------------- #
# Subroutine TransactionBuilder()                                              #
#                                                                              #
# Description:                                                                 #  
# The subroutine is preparing the transaction for the withdraw of balance from #
# the Tron blockchain. This balance is the reward which is available every 24  #  
# hours.                                                                       #
#                                                                              #
# @argument $address    Public key          (scalar)                           #
#           $outflag    Output format flag  (scalar)                           # 
# @return   $json_data  Response content    (scalar)                           #
# ---------------------------------------------------------------------------- #
sub TransactionBuilder {
    # Assign the argument(s) to the local variable.
    my ($args) = @_;
    # Set the local variables.
    # Check the first argument.
    my $address = (defined $args->{address} ? $args->{address} : "");
    # Check the second argument.
    my $outflag = (defined $args->{outflag} ? $args->{outflag} : "");
    # Initialise the return variable.
    my $json_data = ""; 
    # Initialise the other variables. 
    my $payload = "";
    my $content = "";
    # Check address.
    if ($address ne "") {
        # Create the payload string.
        $payload = "\{\"owner_address\":\"$address\"}";
        # Get the content from the service url.
        $content = get_response($payload, $SERVICE_URL_PRE);
        # Format the content for the output.
        if ($outflag eq "RAW") {
            # Set the json data.
            $json_data = $content;    
        } else {
            # Encode the content.
            $json_data = encode($content);
        };
    };
    # Return JSON data.
    return $json_data;
};

# ---------------------------------------------------------------------------- #
# Subroutine BroadcastTransaction()                                            #
# ---------------------------------------------------------------------------- #
sub BroadcastTransaction {
    # Assign the subroutine arguments to the local variables.
    my ($signature, $raw_data_hex, $raw_data) = @_;
    # Create the payload for the broadcast transaction.
    my $payload = "\{\"raw_data\":$raw_data,\"raw_data_hex\": \"$raw_data_hex\",\"signature\":[\"$signature\"]\}";
    # Get the content from the response.
    my $content = get_response($payload, $SERVICE_URL_POST);
    # Return the content.
    return $content;
};

# ---------------------------------------------------------------------------- #
# Subroutine ClaimReward()                                                     #
# ---------------------------------------------------------------------------- #
sub ClaimReward {
    # Assign the subroutine arguments to the local variables.
    my ($args) = @_;
    # Set the local variables.
    my $pubAddr = $args->{pubAddr};
    my $privAddr = $args->{privAddr};
    # Set the outflag. 
    #my $outflag = "RAW";
    my $outflag = "STR";
    # Get the response from the tarnsaction builder.
    my $response = TransactionBuilder({
        address => $pubAddr,
        outflag => $outflag
    });
    # Declare the local variables.   
    my $content;
    my $raw_data;
    my $raw_data_hex;
    my $signature;
    # Try to get the transaction ID.
    my $txID = parse_txID($response);
    # Check if $txID is defined.
    if (defined $txID && $txID ne "") {
        # Get raw data and raw data hex.
        $raw_data_hex = parse_raw_data_hex($response);
        $raw_data = parse_raw_data($response);
        # Sign transaction. 
        $signature = sign_txID($txID, $privAddr);
        # Get the content from broadcast.
        $content = BroadcastTransaction("$signature", "$raw_data_hex", "$raw_data");
    } else {
        # Set content.
        # $content = "{}";
        $content = $response;
    };
    # Return the content.
    return $content;
};

# ---------------------------------------------------------------------------- #
# Subroutine parse_txID()                                                      #
# ---------------------------------------------------------------------------- #
sub parse_txID {
    # Assign the subroutine argument to the local variable.
    my $json_data = $_[0];
    # Set up the options for the Perl module JSON::PP.
    my $json = 'JSON::PP'->new->pretty;
    # Decode the JSON data.
    my $decoded = $json->decode($json_data);
    # Extract the txID from the JSON data.
    my $txID = $decoded->{'txID'};
    # Return the extracted txID.
    return $txID;
};

# ---------------------------------------------------------------------------- #
# Subroutine parse_raw_data_hex()                                              #
# ---------------------------------------------------------------------------- #
sub parse_raw_data_hex {
    # Assign the subroutine argument to the local variable.
    my $json_data = $_[0];
    # Set up the options for the Perl module JSON::PP.
    my $json = 'JSON::PP'->new->pretty;
    # Decode the JSON data.
    my $decoded = $json->decode($json_data);
    # Extract the raw_data from the JSON data.
    my $raw_data_hex = $decoded->{'raw_data_hex'};
    # Return the extracted raw data.
    return $raw_data_hex;
};

# ---------------------------------------------------------------------------- #
# Subroutine parse_raw_data()                                                  #
# ---------------------------------------------------------------------------- #
sub parse_raw_data {
    # Assign the subroutine argument to the local variable.
    my $json_data = $_[0];
    # Set up the options for the Perl module JSON::PP.
    my $json = 'JSON::PP'->new->pretty;
    # Decode the JSON data.
    my $decoded = $json->decode($json_data);
    # Extract the raw_data from the JSON data.
    my $raw_data = $decoded->{'raw_data'};
    #$raw_data = to_json($raw_data);
    $raw_data = encode_json($raw_data);
    # Return the extracted raw data.
    return $raw_data;
};

1;

__END__

=head1 NAME

CryptoTron::ClaimReward - Perl extension for use with the blockchain of the crypto coin Tron.

=head1 SYNOPSIS

  use CryptoTron::ClaimReward;

  # Set the public and private key.
  my $PublicKey = "4113661E105128E9918D50CC9F6ABD83DE10C302FC";
  my $PrivateKey = "315763645E812CD269A326F6A59B971F31101BCB91190503B6C279B63D81A725";
  
  # Get the response from claiming rewards.
  my $response = ClaimReward({
      pubAddr => $PublicKey,
      privAddr => $PrivateKey
  });

  # Print the response into the terminal window.
  print $response;

=head1 DESCRIPTION

Claim rewards from the Tron blockchain.

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
