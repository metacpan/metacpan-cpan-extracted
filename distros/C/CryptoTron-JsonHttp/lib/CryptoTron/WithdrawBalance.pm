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
our $VERSION = '0.03';

# Load the required package module.
use CryptoTron::JsonHttp;

# Load the required Perl module.
use File::Basename;

# Get the package name.
our ($MODULE_NAME, undef, undef) = fileparse(__FILE__, '\..*');

# ---------------------------------------------------------------------------- #
# Subroutine WithdrawBalance()                                                 #
#                                                                              #
# Description:                                                                 #  
# The subroutine is preparing the transaction for the withdraw of balance from #
# the Tron blockchain. This balance is the reward which is available every 24  #  
# hours.                                                                       #
#                                                                              #
# @argument {PublicKey     => $PublicKey,                                      #
#            VisibleFlag => ["True"|"False"|""],                               #
#            ControlFlag => ["True"|"False"|""],                               #
#            OutputFormat => ["RAW"|"STR"|""]}    (hash)                       #
# @return   $output_data  Response content        (scalar)                     #
# ---------------------------------------------------------------------------- #
sub WithdrawBalance {
    # Assign the subroutine arguments to the local array.
    my ($param) = @_;
    # Create the payload.
    my $payload = payload_standard($param);
    # Add the payload to the given hash.
    $param->{'PayloadString'} = $payload;
    # Add the module name to the given hash.
    $param->{'ModuleName'} = $MODULE_NAME;
    # Get the ouput data.
    my $output_data = json_data($param);
    # Return the ouput data.
    return $output_data;
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
