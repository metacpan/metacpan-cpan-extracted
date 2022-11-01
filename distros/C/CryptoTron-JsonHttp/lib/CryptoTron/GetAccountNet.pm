package CryptoTron::GetAccountNet;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(GetAccountNet);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.01';

# Load the required Perl module.
use File::Basename;

# Load the required package module.
use CryptoTron::JsonHttp;

# Get the package name.
my ($MODULE_NAME, undef, undef) = fileparse(__FILE__, '\..*');

# Declare the global variables.
our ($SERVICES, $API_URL, $SERVICE_URL, $METHOD);

# Get service url and related method.
$SERVICE_URL = $API_URL.$SERVICES{$MODULE_NAME}[0];
$METHOD = $SERVICES{$MODULE_NAME}[1];

# ---------------------------------------------------------------------------- #
# Subroutine GetAccountNet()                                                   #
#                                                                              #
# Description:                                                                 #
# Query bandwidth information of a account from the Tron blockchain using the  #
# Full-Node HTTP API.                                                          #
#                                                                              #
# @argument $address    Base58 address      (scalar)                           #
#           $outflag    Output format flag  (scalar)                           # 
#           $visible    Visible switch      (scalar)                           # 
# @return   $json_data  Response content    (scalar)                           #
# ---------------------------------------------------------------------------- #
sub GetAccountNet {
    # Assign the arguments to the local array.
    my ($args) = @_;
    # Set the local variables.
    my $address = (defined $args->{PublicAddr} ? $args->{PublicAddr} : "");
    my $outflag = (defined $args->{OutputFlag} ? $args->{OutputFlag} : "RAW");
    my $visible = (defined $args->{VisibleSwitch} ? $args->{VisibleSwitch} : "True");
    # Initialise the local variables. 
    my $payload = "";
    my $content = "";
    # Initialise the return variable.
    my $json_data = "{}"; 
    # Check if address is not empty.
    if ($address ne "") {
        # Assemble the payload from the address.
        $payload = "\{\"address\":\"$address\",\"visible\":\"$visible\"\}";
        # Get the content from the service url.
        ($content, undef, undef, undef) = HTTP_Request($SERVICE_URL, $METHOD, $payload);
        # Format the content for the output.
        if ($outflag eq "RAW") {
            # Use the content as it is. 
            $json_data = $content;    
        } else {
            # Encode the content.
            $json_data = encode($content);
        };
    };
    # Return the json data.
    return $json_data;
};

1;

__END__

=head1 NAME

CryptoTron::GetAccount - Perl extension for use with the blockchain of the crypto coin Tron.

=head1 SYNOPSIS

  use CryptoTron::GetAccountNet;

  # Set the public key as Base58 address.
  my $PublicKeyBase58 = "TY2fJ7AcsnQhfW3UJ1cjEUak5vkM87KC6R";

  # Set the output format flag.
  my $OutputFlag = ["RAW"|"STR"|""];

  # Set the visible switch.
  my $VisibleSwitch = ["True"|"False"|""];

  # Get the account info from the blockchain.
  my $account_info = GetAccountNet({
      PublicAddr => $PublicKeyBase58
      [, OutputFlag => $OutputFlag]
      [, VisibleSwitch => $VisibleSwitch]
  });

  # Print the account info into the terminal window.
  print $account_info;

=head1 DESCRIPTION

The module requests the account information of an account from the Tron
blockchain using the so-called FULL-NODE HTTP API from the Tron network.
For HTTP requests the methods C<POST> or C<GET> used in general. For the
method C<GetAccount> the used method is C<POST>. The switch visible can be
set to True or False. If the switch is set to True a Base58 address is used.
If the switch is set to False a Hex address is used. A request results in a
response in JSON format. The module returns formated string JSON data as well
as unformated raw JSON data. 

=head1 MODULE METHOD

  GetAccount()

=head1 SEE ALSO

CryptoTron::JsonHttp

CryptoTron:AddressConvert

CryptoTron:AddressCheck

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
