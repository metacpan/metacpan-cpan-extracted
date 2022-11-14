package CryptoTron::GetAccountResource;

# Load the Perl pragmas.
use 5.010001;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Base class of this module.
our @ISA = qw(Exporter);

# Exporting the implemented subroutine.
our @EXPORT = qw(GetAccountResource);

# Set the package version. 
our $VERSION = '0.04';

# Load the required Perl module.
use File::Basename;

# Load the required package module.
use CryptoTron::JsonHttp;

# Get the package name.
our ($MODULE_NAME, undef, undef) = fileparse(__FILE__, '\..*');

# ---------------------------------------------------------------------------- #
# Subroutine GetAccountResource()                                              #
#                                                                              #
# Description:                                                                 #
# Get the resource information of a Tron account (bandwidth, energy etc.)      #
# from the Tron blockchain using the full-node HTTP Tron API.                  #
#                                                                              #
# @argument {PublicKey     => $PublicKey,                                      #
#            VisibleFlag => ["True"|"False"|""],                               #
#            ControlFlag => ["True"|"False"|""],                               #
#            OutputFormat => ["RAW"|"STR"|""]}    (hash)                       #
# @return   $output_data  Response content        (scalar)                     #
# ---------------------------------------------------------------------------- #
sub GetAccountResource {
    # Assign the subroutine arguments to the local array.
    my (%param) = @_;
    # Create the payload.
    my $payload = payload_standard(\%param);
    # Add the payload to the given hash.
    $param{'PayloadString'} = $payload;
    # Add the module name to the given hash.
    $param{'ModuleName'} = $MODULE_NAME;
    # Get the ouput data.
    my $output_data = json_data(\%param);
    # Return the ouput data.
    return $output_data;
};

1;

__END__

=head1 NAME

CryptoTron::GetAccountResource - Perl extension for use with the blockchain of the crypto coin Tron.

=head1 SYNOPSIS

  use CryptoTron::GetAccountResource;

  # Set the public key as Base58 address.
  my $PublicKeyBase58 = "TY2fJ7AcsnQhfW3UJ1cjEUak5vkM87KC6R";

  # Set the visible flag.
  my $VisibleFlag = ["True"|"False"|""];

  # Set the control flag.
  my $ControlFlag = ["True"|"False"|""];

  # Set the output format.
  my $OutputFormat = ["RAW"|"STR"|""];

  # Request the account info from the mainnet.
  my $accountresource_info = GetAccount(
      PublicKey => $PublicKeyBase58
      [, VisibleFlag => $VisibleFlag]
      [, ControlFlag => $ControlFlag]
      [, OutputFormat => $OutputFormat]
  );

  # Print the account info into the terminal window.
  print $accountresource_info;

=head1 DESCRIPTION

The module requests the resource information of an account(bandwidth, energy
etc.) of a Tron account from the Tron blockchain using the full-node HTTP Tron
API from the Tron developer network. The module is designed for use with the
Tron Mainnet. For HTTP requests the methods C<POST> or C<GET> can be used in
general. For the method C<GetAccountResource> the needed method is C<POST>.
The payload of the HTTP request consists of the key 'address' and the key
'visible' and the related values. The switch 'visible' can be set to "True"
or "False". If the switch is set to "True" a Base58 address is used. If the
switch is set to "False" a Hex address is used. A request of the service API
results in a response in JSON format. The module returns formatted string JSON
data as well as unformated raw JSON data based on the output format flag. The
parsing of the account information is done by a separate module.

=head1 METHOD

  GetAccountResource()

=head1 OPTIONS

The named subroutine argument key C<PublicKey> and the related value are
mandatory, the named subroutine arguments keys C<OutputFormat> as well as
C<VisibleFlag> and there values are optional. The value of the subroutine
argument key C<PublicKey> can be a Base58 address or a Hex address. The
value of the subroutine argument key C<VisibleFlag> can be "True" or
"False".

PublicKey: Base58 address => VisibleFlag: True

PublicKey: Hex address    => VisibleFlag: False

If the given combination is not valid, an error will be returned from the
request.

The subroutine argument key C<ControlFlag> and his value controls if the given
combination address and visible should be checked. If visible is not set in a
correct way, the value will be corrected if the flag is "True" and if the flag
is "False" it will not be corrected.

The subroutine argument key C<OutputFormat> and his value controls wether the
output is raw JSON or or formatted JSON.

=head1 METHOD RETURN

=begin html

<table>
<tr><td>PARAMETER</td><td>DESCRIPTION</td></tr>
<tr><td>NetUsed</td><td>Used amount of bandwidth obtained by staking</td></tr>
<tr><td>NetLimit</td><td>Total bandwidth obtained by staking</td></tr>
<tr><td>freeNetUsed</td><td>free bandwidth used</td></tr>
<tr><td>freeNetLimit</td><td>Total free bandwidth</td></tr>
<tr><td>TotalNetLimit</td><td>Total bandwidth can be obtained by staking</td></tr>
<tr><td>TotalNetWeight</td><td>Total TRX staked for bandwidth</td></tr>
<tr><td>tronPowerUsed</td><td>Tron power used</td></tr>
<tr><td>tronPowerLimit</td><td>TRON Power(vote)</td></tr>
<tr><td>EnergyUsed</td><td>Energy used</tdr></tr>
<tr><td>EnergyLimit</td><td>Total energy obtained by staking</td></tr>
<tr><td>TotalEnergyLimit</td><td>Total energy can be obtained by staking</td></tr>
<tr><td>TotalEnergyWeight</td><td>Total TRX staked for energy</td></tr>
</table>

=end html

=head1 EXAMPLES

=head2 Example 1

  # Load the required module.
  use CryptoTron::GetAccountResource;

  # Set the public key as Base58 address.
  my $PublicKeyBase58 = "TY2fJ7AcsnQhfW3UJ1cjEUak5vkM87KC6R";

  # Set the visible flag.
  my $VisibleFlag = "True";

  # Set the control flag.
  my $ControlFlag = "True";

  # Set the output format.
  my $OutputFormat = "RAW";

  # Request the account info from the mainnet.
  my $account_info = GetAccountResource({
      PublicKey => $PublicKeyBase58,
      VisibleFlag => $VisibleFlag,
      ControlFlag => $ControlFlag,
      OutputFormat => $OutputFormat
  });

  # Print the resource info into the terminal window.
  print $account_info;

=head2 Example 2

  # Load the required module.
  use CryptoTron::GetAccountResource;

  # Set the public key as Base58 address.
  my $PublicKeyBase58 = "TY2fJ7AcsnQhfW3UJ1cjEUak5vkM87KC6R";

  # Set the output format.
  my $OutputFormat = "STR";

  # Request the account info from the mainnet.
  my $response = GetAccountResource({PublicKey => $PublicKeyBase58});

  # Print the resource info into the terminal window.
  print $response;

=head1 LIMITATIONS

The module is working with the Tron Mainnet, but not with other existing
Tron Testnets. 

=head1 OPEN ISSUES

None

=head1 ERROR CODES

None

=head1 NOTES

None

=head1 BUGS

None

=head1 TODO

None

=head1 SEE ALSO

CryptoTron::JsonHttp

CryptoTron:ParseAccount

CryptoTron:AddressCheck

CryptoTron:AddressConvert

File::Basename

L<TRON Developer Hub|https://developers.tron.network/>

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify it
under the same terms of The MIT License. For more details, see the full
text of the license in the attached file LICENSE in the main module folder.
This program is distributed in the hope that it will be useful, but without
any warranty; without even the implied warranty of merchantability or fitness
for a particular purpose.

=cut
