package CryptoTron::JsonHttp;

# Load the Perl pragmas.
use 5.010000;
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
    encode
    encode_data
    json_data
    format_output
    %SERVICES
    $API_URL
);

# Set alias.
*encode = \&encode_data;

# Set the package version. 
our $VERSION = '0.09';

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
# Function json_data()                                                         #
# ---------------------------------------------------------------------------- #
sub json_data {
    # Assign the arguments to the local array.
    my ($args) = @_;
    # Set the local variables.
    my $address = (defined $args->{PublicAddr} ? $args->{PublicAddr} : "");
    my $outflag = (defined $args->{OutputFlag} ? $args->{OutputFlag} : "RAW");
    my $visible = (defined $args->{VisibleSwitch} ? $args->{VisibleSwitch} : "True");
    my $addrchk = (defined $args->{AddrCheck} ? $args->{AddrCheck} : "True");
    # Get the name of the calling module.   
    my $module_name = $args->{ModuleName};
    # Get service url and related method.
    my $service_url = $API_URL.$SERVICES{$module_name}[0];
    my $method = $SERVICES{$module_name}[1];
    # Initialise the local variables. 
    my $payload = "";
    my $content = "";
    # Initialise the return variable.
    my $output_data = "{}";
    # Check if address is not empty.
    if ($address ne "") {
        # Check if address check is set to True.
        $visible = (($visible eq "True" && chk_base58_addr($address) != 1) ? "False" : "True"); 
        $visible = (($visible eq "False" && chk_hex_addr($address) != 1) ? "True" : "False"); 
        # Create the payload from the address.
        $payload = "\{\"address\":\"$address\",\"visible\":\"$visible\"\}";
        # Get the content from the service url.
        ($content, undef, undef, undef) = HTTP_Request($service_url, $method, $payload);
        # Format the content for the output.
        $output_data = format_output($content, $outflag);
    };
    # Return the JSON data raw or formatted.
    return $output_data;
};

# ---------------------------------------------------------------------------- #
# Function format_output()                                                     #
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
# Function encode_data()                                                       #
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
# Function HTTP_Request()                                                      # 
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
