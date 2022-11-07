package CryptoTron::JsonHttp;

# Load the Perl pragmas.
use 5.008008;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Exporting the implemented subroutine.
our @EXPORT = qw(
    HTTP_Request
    encode_data
    json_data
    format_output
    payload_standard
    %SERVICES
    $API_URL
);

# Set the package version. 
our $VERSION = '0.13';

# Load the required Perl modules or packages.
use JSON::PP;
use URI;
use LWP::UserAgent;

# Load the required modules.
use CryptoTron::AddressCheck; 

# Set api url and api path.
our $API_URL = 'https://api.trongrid.io';

# Define the hash with the services.
our %SERVICES = (
    'GetNextMaintenanceTime' => ['/wallet/getnextmaintenancetime', 'GET'],
    'BroadcastTransaction'   => ['/wallet/broadcasttransaction',   'POST'],
    'FreezeBalance'          => ['/wallet/freezebalance',          'POST'],
    'GetAccount'             => ['/walletsolidity/getaccount',     'POST'],
    'GetBrokerage'           => ['/wallet/getBrokerage',           'POST'],
    'GetAccountBalance'      => ['/wallet/getaccountbalance',      'POST'],
    'GetAccountNet'          => ['/wallet/getaccountnet',          'POST'],
    'GetAccountResource'     => ['/wallet/getaccountresource',     'POST'],
    'GetReward'              => ['/wallet/getReward',              'POST'],
    'UnfreezeBalance'        => ['/wallet/unfreezebalance',        'POST'],
    'WithdrawBalance'        => ['/wallet/withdrawbalance',        'POST']
);

# Configure a new JSON:PP object.
our $indent_enable = "true";
our $indent_spaces = 4;
our $JSON;
$JSON = 'JSON::PP'->new->pretty;
$JSON = $JSON->indent($indent_enable);
$JSON = $JSON->indent_length($indent_spaces);
$JSON = $JSON->allow_unknown("true");
$JSON = $JSON->allow_blessed("true");
$JSON = $JSON->allow_singlequote("true");

# ---------------------------------------------------------------------------- #
# Subroutine payload_standard()                                                #
# ---------------------------------------------------------------------------- #
sub payload_standard {
    # Assign the subroutine arguments to the local array.
    my ($args) = @_;
    # Set the local variables.
    my $addr = $args->{PublicKey};
    my $flag = $args->{VisibleFlag};
    my $chk = $args->{ControlFlag};
    # Check if the the local variables are defined.
    $addr = (defined $addr ? $addr : "");
    $chk = (defined $chk ? $chk : "True");
    $flag = (defined $flag ? $flag : "True");
    # Initialise the local variable $payload. 
    my $payload = "";
    # Check if the $address is not empty.
    if ($addr ne "") {
        if ($chk eq "True") { 
            # Check variable $visible.
            my $isBase58Addr = ($flag eq "True" && chk_base58_addr($addr) != 1); 
            my $isHexAddr = ($flag eq "False" && chk_hex_addr($addr) != 1);
            $flag = ($isBase58Addr ? "False" : "True"); 
            $flag = ($isHexAddr ? "True" : "False"); 
        };
        # Create the payload from the address.
        $payload = "\{\"address\":\"${addr}\",\"visible\":\"${flag}\"\}";
    };
    # Return the payload string.
    return $payload;    
};

# ---------------------------------------------------------------------------- #
# Subroutine json_data()                                                       #
# ---------------------------------------------------------------------------- #
sub json_data {
    # Assign the arguments to the local array.
    my ($args) = @_;
    # Set the local variables.
    my $outfmt = (defined $args->{OutputFormat} ? $args->{OutputFormat} : "RAW");
    # Get the name of the calling module.   
    my $module_name = $args->{ModuleName};
    # Get the payload string.
    my $payload = $args->{PayloadString};
    # Get service url and related method.
    my $service_url = $API_URL.$SERVICES{$module_name}[0];
    my $method = $SERVICES{$module_name}[1];
    my $content = "";
    # Initialise the return variable.
    my $output_data = "{}";
    # Get the content from the service url.
    ($content, undef, undef, undef) = HTTP_Request($service_url, $method, $payload);
    # Format the content for the output.
    $output_data = format_output($content, $outfmt);
    # Return the JSON data raw or formatted.
    return $output_data;
};

# ---------------------------------------------------------------------------- #
# Subroutine format_output()                                                   #
# ---------------------------------------------------------------------------- #
sub format_output {
    # Assign the subroutine arguments to the local variables.
    my ($content, $outflag) = @_;
    # Declare the return variable.
    my $output;
    # Format the content for the output.
    if ($outflag eq "RAW") {
        # Use the content as it is. 
        $output = $content;
    } else {
        # Encode the content.
        $output = encode_data($content);
    };
    # Return formatted output.
    return $output;
};
# ---------------------------------------------------------------------------- #
# Subroutine encode_data()                                                     #
#                                                                              #
# Description:                                                                 # 
# At first glance, it is not obvious why the response should be decoded and    #
# then encoded back again. However, if one assumes that the response can have  #
# any structure, this procedure makes sense. Decoding creates a Perl data      #
# structure from the response. Encoding then creates a formatted string from   #
# the Perl data structure.                                                     #
#                                                                              #
# @argument $content  Content from response      (scalar)                      #
# @return   $encoded  Encoded formatted content  (scalar)                      #
# ---------------------------------------------------------------------------- #
sub encode_data {
    # Assign the subroutine argument to the local variable.
    my $content = $_[0];
    # Decode the content of the response using 'JSON:PP'.
    my $decoded = $JSON->decode($content);
    # Encode the content of the response using 'JSON:PP'.
    my $encoded = $JSON->encode($decoded);
    # Return the encoded formatted JSON content.
    return $encoded;
};

# ---------------------------------------------------------------------------- #
# Subroutine HTTP_Request()                                                    # 
#                                                                              #
# Description:                                                                 #
# The subroutine is using the HTTP methods GET or POST to send a request to a  #
# known servive url of the FULL-NODE HTTP API. On success a content in form of #
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
    # Create a new uri object from the service url.
    my $uri = URI->new($service_url);
    # Create a new user agent object.
    my $ua = LWP::UserAgent->new();
    # Set the default header of the request.
    $ua->default_header('Accept' => 'application/json');
    $ua->default_header('Content_Type' => 'application/json');
    # Get the response from the uri based on the given HTTP method.
    if ($method eq 'POST') {
        $response = $ua->post($uri, 'Content' => $payload);
    } elsif ($method eq 'GET') {
        $response = $ua->get($uri, 'Content' => $payload);
    };
    # Get error code and error message.
    $errcode = $response->code;
    $errmsg = $response->message;
    # Check success of operation.
    if ($response->is_success) {
        # Get the content from the response.
        $content = $response->content;
    } else {
        # Set the content to an empty string.
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

The MIT License
 
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the
following conditions:
 
The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the
Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
