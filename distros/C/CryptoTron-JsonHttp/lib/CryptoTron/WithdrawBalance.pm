package CryptoTron::WithdrawBalance;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(WithdrawBalance);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.02';

# Load the required Perl modules or packages.
use URI;
use LWP::UserAgent;
use JSON::PP;

# Load the required package module.
use CryptoTron::JsonHttp;

# Set the variable $JSON.
our $JSON = 'JSON::PP'->new->pretty;

# Define the global variables.
our($HEADER, $SERVICE_URL);

# Set api url and api path.
our $API_URL = 'https://api.trongrid.io';
our $API_PATH = '/wallet/withdrawbalance';

# Set the request header.
$HEADER = [Accept => 'application/json',
           Content_Type => 'application/json'];

# Assemble the service url.
$SERVICE_URL = $API_URL.$API_PATH;

# Set the HTTP request method.
our $METHOD = "POST";

# ---------------------------------------------------------------------------- #
# Subroutine WithdrawBalance()                                                 #
#                                                                              #
# Description:                                                                 #  
# The subroutine is preparing the transaction for the withdraw of balance from #
# the Tron blockchain. This balance is the reward which is available every 24  #  
# hours.                                                                       #
#                                                                              #
# @argument $privKey    Private Key         (scalar)                           #
#           $flag       Output format flag  (scalar)                           # 
# @return   $json_data  Response content    (scalar)                           #
# ---------------------------------------------------------------------------- #
sub WithdrawBalance {
    # Assign the argument(s) to the local variable.
    my ($args) = @_;
    # Set the local variables.
    my $address = $args->{address};
    my $outflag = $args->{outflag};
    # Check the first argument.
    $address = (defined $address ? $address : "");
    # Check the second argument.
    $outflag = (defined $outflag ? $outflag : "");
    # Initialise the return variable.
    my $json_data = ""; 
    # Initialise the other variables. 
    my $payload = "";
    my $content = "";
    # Check address.
    if ($address ne "") {
        my $payload = "\{\"owner_address\":\"$address\",\"visible\":\"True\"\}";
        # Get the content from the service url.
        ($content, undef, undef, undef) = HTTP_Request($SERVICE_URL, $METHOD, $payload);
        # Format the content for the output.
        if ($outflag eq "RAW") {
            $json_data = $content;    
        } else {
            # Encode the content.
            $json_data = encoded($content);
        };
    };
    # Return JSON data.
    return $json_data;
};

1;

__END__

=head1 NAME

CryptoTron::WithdrawBalance - Perl extension for use with the blockchain of the crypto coin Tron.

=head1 SYNOPSIS

  use CryptoTron::WithdrawBalance;

  # Declare the public keys.
  my $PublicKeyBase58 = 'TQHgMpVzWkhSsRB4BzZgmV8uW4cFL8eaBr';

  # Set the output format flag.
  my $OutputFlag = ["RAW"|"STR"];

  # Get the account info as JSON string.
  my $account_info = WithdrawBalance({
      address => $PublicKeyBase58
      [,flag    => $OutputFlag]
  });

  # Print the account info into the terminal window.
  print $account_info;

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
