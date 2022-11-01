package CryptoTron::ParseAccount;

# Load the Perl pragmas.
use 5.010000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutine.
our @EXPORT = qw(
    TotalBalance
    FreeBalance
    FrozenBalance
    CreateTime
    LatestWithdrawTime
    NextWithdrawTime
);

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.04';

# Load the required Perl module.
use Try::Catch;
use JSON::PP;
use POSIX;

# Set the variable $SUN.
our $SUN = 1000000;

# Set the variable $JSON.
our $JSON = 'JSON::PP'->new->pretty;

# Set the array with the keys.
our @KEYS = ('balance',
             'frozen',
             'frozen_balance',
             'account_resource',
             'frozen_balance_for_energy'
);

# Create an array with the time keywords.
my @TIME_KEYS = ('create_time',
                 'latest_withdraw_time'
);

# ---------------------------------------------------------------------------- #
# Subroutine date_time()                                                       #
#                                                                              #
# Description:                                                                 #
# Create a date and time string.                                               #
#                                                                              #
# @argument $_[0] -> $dt_ms  Raw JSON data   (scalar)                          #
# @return   $date_time       Frozen balance  (scalar)                          #
# ---------------------------------------------------------------------------- #
sub date_time {
    # Assign the argument to the local variable.
    my $dt_ms = (defined $_[0] ? $_[0] : 0);
    # Set the required devisor.
    my $milliseconds = 1000;
    # Get the date and time number. 
    my $dt_sec = int($dt_ms / $milliseconds);
    # Create the date and time string.
    my $date_time = strftime "%Y-%m-%d %H:%M:%S", localtime($dt_sec);
    # Return the date and time string.
    return $date_time;
};

# ---------------------------------------------------------------------------- #
# Subroutine getValues()                                                       #
#                                                                              #
# Description:                                                                 #
# Parse the JSON account data and determine the relevant balance values.       #
#                                                                              #
# @argument $_[0] -> $json_data        Raw JSON data   (scalar)                #
# @return   ($free, $frozen, $energy)  Balance values  (array)                 #
# ---------------------------------------------------------------------------- #
sub getValues{
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Declare the local variables.
    my $decoded;
    my $free;
    my $frozen;
    my $energy;
    # Try to decode the JSON data.
    try {
        # Decode the JSON data to get a valid hash.
        $decoded = $JSON->decode($json_data);
        # Get the balance values from the JSON data.
        $free = $decoded->{$KEYS[0]};
        $frozen = $decoded->{$KEYS[1]}[0]{$KEYS[2]};
        $energy = $decoded->{$KEYS[3]}{$KEYS[4]}{$KEYS[2]};
    } catch {
        # Silent interception of an error.
        # print "Something went wrong using the raw JSON data.\n";
        ;
    };
    # Check the values.
    $free = (defined $free ? $free : 0);
    $frozen = (defined $frozen ? $frozen : 0);
    $energy = (defined $energy ? $energy : 0);
    # Return the balance values.
    return ($free, $frozen, $energy);
};

# ---------------------------------------------------------------------------- #
# Subroutine TotalBalance()                                                    #
#                                                                              #
# Description:                                                                 #
# Parse the JSON account data and determine the total balance.                 #
#                                                                              #
# @argument $_[0] -> $json_data  Raw JSON data  (scalar)                       #
# @return   $total_balance       Total balance  (scalar)                       #
# ---------------------------------------------------------------------------- #
sub TotalBalance {
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Get all balance values.
    my ($free, $frozen, $energy) = getValues($json_data);
    # Calculate the total balance.
    my $total_balance = ($free + $frozen + $energy) / $SUN;
    # Return the total balance.
    return $total_balance;
};

# ---------------------------------------------------------------------------- #
# Subroutine FreeBalance()                                                     #
#                                                                              #
# Description:                                                                 #
# Parse the JSON account data and determine the free balance.                  #
#                                                                              #
# @argument $_[0] -> $json_data  Raw JSON data  (scalar)                       #
# @return   $free_balance        Free balance   (scalar)                       #
# ---------------------------------------------------------------------------- #
sub FreeBalance {
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Get all balance values.
    my ($free, undef, undef) = getValues($json_data);
    # Calculate the free balance.
    my $free_balance = $free / $SUN;
    # Return the free balance.
    return $free_balance;
};

# ---------------------------------------------------------------------------- #
# Subroutine FrozenBalance()                                                   #
#                                                                              #
# Description:                                                                 #
# Parse the JSON account data and determine the frozen balance.                #
#                                                                              #
# @argument $_[0] -> $json_data  Raw JSON data   (scalar)                      #
# @return   $frozen_balance      Frozen balance  (scalar)                      #
# ---------------------------------------------------------------------------- #
sub FrozenBalance {
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Get all balance values.
    my (undef, $frozen, $energy) = getValues($json_data);
    # Calculate the total frozen balance.
    my $total_frozen = ($frozen + $energy) / $SUN;
    # Return the total frozen balance.
    return $total_frozen;
};

# ---------------------------------------------------------------------------- #
# Subroutine getTimeValues()                                                   #
# ---------------------------------------------------------------------------- #
sub getTimeValues {
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Declare the local variables.
    my $decoded;
    my $create_time;
    my $latest_withdraw_time;
    my $next_withdraw_time;
    # Try to decode the JSON data.
    try {
        # Decode the JSON data to get a valid hash.
        $decoded = $JSON->decode($json_data);
        # Get the balance values from the JSON data.
        $create_time = date_time($decoded->{$TIME_KEYS[0]});
        $latest_withdraw_time = date_time($decoded->{$TIME_KEYS[1]});
        $next_withdraw_time = date_time($decoded->{$TIME_KEYS[1]} + 86400*1000);
    } catch {
        # Silent interception of an error.
        # print "Something went wrong using the raw JSON data.\n";
        ;
    };
    # Check the values.
    $create_time = (defined $create_time ? $create_time : 0);
    $latest_withdraw_time = (defined $latest_withdraw_time ? $latest_withdraw_time : 0);
    $next_withdraw_time = (defined $next_withdraw_time ? $next_withdraw_time : 0);
    # Return the balance values.
    return ($create_time, $latest_withdraw_time, $next_withdraw_time);
};

# ---------------------------------------------------------------------------- #
# Subroutine LastWithdrawTime()                                                #
# ---------------------------------------------------------------------------- #
sub LatestWithdrawTime {
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Get the time values.
    my (undef, $latest_withdraw_time, undef) = getTimeValues($json_data);
    # Return the array with the data.
    return $latest_withdraw_time;
};

# ---------------------------------------------------------------------------- #
# Subroutine NextWithdrawTime()                                                #
# ---------------------------------------------------------------------------- #
sub NextWithdrawTime {
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Get the time values.
    my (undef, undef, $next_withdraw_time) = getTimeValues($json_data);
    # Return the array with the data.
    return $next_withdraw_time;
};

# ---------------------------------------------------------------------------- #
# Subroutine CreateTime()                                                      #
# ---------------------------------------------------------------------------- #
sub CreateTime {
    # Assign the argument to the local variable.
    my $json_data = (defined $_[0] ? $_[0] : '{}');
    # Get the time values.
    my ($create_time, undef, undef) = getTimeValues($json_data);
    # Return the array with the data.
    return $create_time;
};

1;

__END__

=head1 NAME

CryptoTron::GetAccount - Perl extension for use with the blockchain of the crypto coin Tron.

=head1 SYNOPSIS

  use CryptoTron::ParseAccount;

  # Initialise the variable $balance.
  my $balance = 0;

  # Set the JSON data.
  my $json_data = '{"balance": 1000000000, 
                    "frozen": [{"frozen_balance": 2000000000}],
                    "account_resource": {"frozen_balance_for_energy": {"frozen_balance": 300000000}}}';

  # Get the total balance.
  $balance = TotalBalance($json_data);
  print $balance;

  # Get the free balance.
  $balance = FreeBalance($json_data);
  print $balance;

  # Get the frozen balance.
  $balance = FrozenBalance($json_data);
  print $balance;

=head1 DESCRIPTION

The module consists of methods for parsing raw JSON data. The raw JSON data
can come from the module CryptoTron::GetAccount or other sources, as long it
is a valid JSON object.

A distinction is made between a freely available Tron amount and a frozen Tron
amount. The frozen Tron amount differs in ENERGY and BANDWIDTH. The Tron amount
of interest is output with a decimal point and has a maximum of 6 digits after
the decimal point.

If the raw JSON data is malformed, an exception is captured silently. The
resulting amount values will be set to zero.

=head1 METHODS

Methods implemented so far:

  TotalBalance()

  FreeBalance()

  FrozenBalance()

  CreateTime()

  LastWithdrawTime()

  NextWithdrawTime()

=head1 SEE ALSO

CryptoTron::GetAccount

POSIX

JSON::PP

Try::Catch

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
