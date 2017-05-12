package Business::BankAccount::NZ;

# name:     $RCSfile: NZ.pm,v $
# process:  Validates bank account numbers (See below)
# author:   John Bolland, Becky Alcorn, Simon Taylor
# revision: $Id: NZ.pm,v 1.4 2003/01/07 00:29:49 simon Exp $

=head1 NAME

B<Business::BankAccount::NZ> - validates New Zealand bank account numbers

=head1 SYNOPSIS

  use Business::BankAccount::NZ;
  
  # Returns a hash table with bank data in it (if specified)
  my $nz = Business::BankAccount::NZ->new(
      bank_no => '030510',
      account_no => '072049700'
  );
  
  # Or set the bank and account numbers independantly of new()
  my $nz = Business::BankAccount::NZ->new();
  $nz->set_bank_no('086523');
  $nz->set_account_no('1954512001');
  
  # Either way, you'd validate the account number with...
  $nz->validate() or die "$nz->{error_string}";
  
  print $nz->{error_string} if ($nz->{error});
  
  print "The bank name is " . $nz->{bank_name} . "\n";

=head1 DESCRIPTION

This module provides validation on New Zealand bank account numbers.

The extent of the validation is simply that the account number is checked
to ensure that it conforms with the notion of an account number laid out 
in the 'Bank Account Number Check Digit Validation Routines' brochure prepared 
by the Bank of New Zealand, dated 27 October, 1999.

Thus the module does not tell you whether or not a given bank account number 
is an B<actual> account known to the bank, just that it is a B<valid> number
according to their rules.

The module uses validation code developed by John Bolland.

=head1 METHODS

=cut

require 5;
use Carp;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.02";
my $module = "NZ.pm";

=head2 new

The minimum invocation is:

  use Business::BankAccount::NZ;
  $nz = Business::BankAccount::NZ->new(
      bank_no => '033565', 
      account_no => '384642737'
  );
  $nz->validate();

=cut

sub new
{
    my ($class, %arg) = @_;

    #
    # Bless an anonymous hash for this class and new() will return a 
    # reference to it
    #

    my $self = {};
    $self->{bank_no} = $arg{bank_no} if ($arg{bank_no});
    $self->{account_no} = $arg{account_no} if ($arg{account_no});
    $self->{bank_name} = "";
    $self->{res} = '';

    bless($self, $class);

    return $self;
}

=head2 set_bank_no

Sets the bank number against whose rules we wish to validate an account number.

  $nz->set_bank_no('168392');

=cut

sub set_bank_no {
    my ($self, $bank_no) = @_;
    $self->{bank_name} = "";
    $self->{bank_no} = $bank_no;
}

=head2 set_account_no

Sets the account number we wish to validate.

    $nz->set_account_no('02836723000');

=cut

sub set_account_no {
    my ($self, $account_no) = @_;
    $self->{res} = 0;
    $self->{account_no} = $account_no;
}

=head2 validate

  $nz->validate();

This method checks the bank number and validates the account number.

The validation is based rules set out in the 'Bank Account Number Check Digit 
Validation Routines' brochure prepared by the Bank of New Zealand, 
dated 27 October, 1999.

The "error" and "error_string" attributes are set if validate() fails. The
"bank_name" attribute contains the bank name identified by the bank number.

  $nz->validate() or die "$nz->{error_string}";
  print $nz->{error_string} if ($nz->{error});
  
  print "The bank name is " . $nz->{bank_name} . "\n";

=cut

#
# Returns 0 and an error message if failed, or 1 and '' if success
#
sub validate {
    my ($self, $account_no) = @_;

    $self->{error} = 0;
    $self->{error_string} = "";
    $self->{res} = '';

    # Check for an account number
    if (!$account_no && !$self->{account_no}) {
	$self->{error} = 1;
	$self->{error_string} = "No account number specified";
        return 0;
    }

    # Check the length of the account number
    my $len = length($self->{account_no});
    if ($len < 8 || $len > 10) {
	$self->{error} = 1;
	$self->{error_string} = 
     "Account number must be from 8 to 10 characters long: $self->{account_no}";
	return 0;
    }

    # Check for a bank number
    if (!$self->{bank_no}) {
	$self->{error} = 1;
	$self->{error_string} = "No bank number specified";
	return 0;
    }

    # Check length of bank number
    if (length ($self->{bank_no}) != 6) {
	$self->{error} = 1;
	$self->{error_string} = 
           "Bank number must be six characters long: $self->{bank_no}";
	return 0;
    }


    # $self->{bank} is bk
    # $self->{branch} is br
    # $self->{account} is ac
    # $self->{suffix} is as

    # Determine the bank and do initial validation
    $self->{bank} = substr($self->{bank_no}, 0, 2);
    # Minor validation of bank number
    if (($self->{bank} < 0) || ($self->{bank} > 32 && $self->{bank} != 38)) {
	$self->{error} = 1;
	$self->{error_string} = "The bank must be a valid bank number: $self->{bank}";
	return 0;
    }
    # Determine the branch and do initial validation
    ($self->{branch} = $self->{bank_no}) =~ s/^.{2}//;
    # Determine the account (minus suffix) and do initial validation
    $self->{account} = substr($self->{account_no},0, 7);
    # Determine the suffix and do initial validation
    ($self->{suffix} = $self->{account_no}) =~ s/^.{7}//;

    # Choose the bank and validate accordingly
    if ($self->{bank} eq '08') {
	$self->{bank_name} = "National Australia Bank";
	nab_account($self);
	return 0 if ($self->{error});
    } elsif ($self->{bank} eq '09') {
	$self->{bank_name} = "Reserve Bank";
	rb_account($self);
	return 0 if $self->{error};
    } elsif ($self->{bank} eq '29') {
	$self->{bank_name} = "United Bank";
	ub_account($self);
	return 0 if ($self->{error});
    } elsif ($self->{bank} eq '25') {
	$self->{bank_name} = "CountryWide and Rural Banks";
	cwrb_account($self);
	return 0 if ($self->{error});
    } elsif ($self->{bank} eq '04' || $self->{bank} eq '05' || 
             $self->{bank} eq '07' || $self->{bank} eq '10' ||
             $self->{bank} eq '26' || $self->{bank} eq '28' ||
             $self->{bank} eq '33') {
	# Not supported banks
	$self->{error} = 2;
	$self->{error_string} = "This bank not supported: $self->{bank}";
	return 0;
    } else {
	# Anything else (including Bank of NZ)
	$self->{bank_name} = "Other Banks";
	other_account($self);
	return 0 if ($self->{error});
    }
    
    return 1;
}

#-------------------------------------------------------------------------
# Subroutines for validating the various account numbers
#

# National Australia Bank
#
# Each digit is multiplied by a corresponding value in the @vals array
# and added to the total.  The total is then divided by 11.  If there
# is a remainer then the account number is invalid.
#
sub nab_account($) {
    my ($self) = @_;
    # Get account digits in an array
    my @acc = get_acc_array($self->{account_no});
    # Values by which to multiply the digits
    my @vals = (7, 6, 5, 4, 3, 2, 1);
    my $res = 0;
    # The suffix
    my $suff = $self->{suffix};

    # We only deal with suffixes 3 digits long
    if (length($suff) == 3) {
	# Multiply each values and add to result
        for (my $i = 0; $i < scalar(@vals); $i++) {
	    $res += ($acc[$i] * $vals[$i]);
        }

	# For debugging purposes
	$self->{res} = $res;

	# Mod the result by 11
        #$res = ($res / 11) - int($res / 11);
	$res = $res % 11;
    } else {
	# Suffix not 3 digits long
	$self->{error} = 3;
	$self->{error_string} = "Invalid suffix: $suff";
	return 0;
    }

    # If the result is 0 the its a valid account number
    if ($res == 0) {
        return 1;
    } else {
	# Result was not 0 so return an error
	$self->{error} = 1;
	$self->{error_string} = "Invalid account number: $self->{account_no}";
	return 0;
    }
}

# Reserve Bank
#
# Each digit is multiplied by a corresponding value in the @vals array.
# If the result is more than 1 digit long then the digits are added together
# and that result is added to the total.  The total is then divided by 11.  If there
# is a remainer then the account number is invalid.
#
sub rb_account($) {
    my ($self) = @_;
    # Get the account number digits
    my @acc = get_acc_array($self->{account_no});
    # The suffix
    my $suff = $self->{suffix};
    # The values by which the account number digits are multiplied
    my @vals = (0, 0, 0, 5, 4, 3, 2);
    my $res = 0;
    # We only deal with suffixes of one digit
    if (length($suff) == 1) {
	# Do the multiplications and if a number is larger than one digit 
        # then add the digits together.
	for (my $i = 0; $i < scalar(@vals); $i++) {
	    $res += multi_add($acc[$i], $vals[$i]);
 	}

	# Add the suffix to the result
	$res += $suff;

	# For debugging
	$self->{res} = $res;

	# Modules the result by 11
        #$res = ($res / 11) - int($res / 11);
	$res = $res % 11;
    } else {
	# Suffix was not 1 digit
	$self->{error} = 5;
	$self->{error_string} = "Invalid suffix: $suff";
	return 0;
    }

    # If the result is 0 then its a valid account number
    if ($res == 0) {
        return 1;
    } else {
	# Result was not 0 so return an error
	$self->{error} = 1;
	$self->{error_string} = "Invalid account number: $self->{account_no}";
	return 0;
    }
}

# United Bank
# NOTE: uses multi_add2 not multi_add
#
# Each digit of the account number and the suffix is multiplied by a corresponding 
# value in the @vals or @vals2 arrays.  If the result is more than 1 digit long then 
# the digits are added together until the result is only 1 digit long, and that result 
# is added to the total.  The total is then divided by 10.  If there is a remainer 
# then the account number is invalid.
#
sub ub_account($) {
    my ($self) = @_;
    # Get the digits of the account number
    my @acc = get_acc_array($self->{account_no});
    # The suffix
    my $suff = $self->{suffix};
    # Get the digits of the suffix
    my @suffs = get_acc_array($suff);
    # Values to multiply the account number digits by
    my @vals = (1, 3, 7, 1, 3, 7, 1);
    # Values to multiply the suffix digits by
    my @vals2 = (3, 7, 1);
    my $res = 0;

    # Validate the suffix
    if (length($suff) == 3) {
	# Do the multiplications and if a number is larger than one digit 
        # then add the digits together until there is only one digit.
	
	# Account number digits
	for (my $i = 0; $i < scalar(@vals); $i++) {
	    $res += multi_add2($acc[$i], $vals[$i]);
 	}
	# Suffix digits
	for (my $i = 0; $i < scalar(@vals2); $i++) {
	    $res += multi_add2($suffs[$i], $vals2[$i]);
 	}

	# For debugging
	$self->{res} = $res;

	# Modules the result by 10
        #$res = ($res / 10) - int($res / 10);
	$res = $res % 10;
	
    } else {
	# Suffix wasn't 3 digits, so error
	$self->{error} = 3;
	$self->{error_string} = "Invalid suffix: $suff";
        return 0;
    }

    # If the result was zero then the account number is good
    if ($res == 0) {
        return 1;
    } else {
	# Result was not zero so error
	$self->{error} = 1;
	$self->{error_string} = "Invalid account number: $self->{account_no}";
	return 0;
    }

}

# CountryWide and Rural banks
#
# Each digit is multiplied by a corresponding value in the @vals array 
# and the result is added to the total.  The total is then divided by 10.  If there
# is a remainer then the account number is invalid.
#
sub cwrb_account($) {
    my ($self) = @_;
    # The account number digits
    my @acc = get_acc_array($self->{account_no});
    # The suffix
    my $suff = $self->{suffix};
    # The values to multiply with
    my @vals = (1, 7, 3, 1, 7, 3, 1);
    my $res = 0;
    
    # Validate the suffix
    if (length($suff) == 3) {
	# Do the multiplications 
	for (my $i = 0; $i < scalar(@vals); $i++) {
	    $res += ($acc[$i] * $vals[$i]);
 	}

	# Debugging
	#self->{res} = $res;

	# Mod the result
        #$res = ($res / 10) - int($res / 10);
	$res = $res % 10;
    } else {
	# Suffix wasn't 3 digits, so error
	$self->{error} = 3;
	$self->{error_string} = "Invalid suffix: $suff";
        return 0;
    }

    # If the result is 0 then the account number is good
    if ($res == 0) {
        return 1;
    } else {
	# The result wasn't 0, so error
	$self->{error} = 1;
	$self->{error_string} = "Invalid account number: $self->{account_no}";
	return 0;
    }

}

# The normal case (21 banks)
#
# Each digit of the account number and the branch is multiplied by a corresponding 
# value in the @vals or @vals2 arrays and the result is added to the total.  The 
# total is then divided by 11.  If there is a remainer then the account number 
# is invalid.
#
# Banks include:
# 01, 02, 03, 06, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 27, 30 and 31
sub other_account($) {
    my ($self) = @_;
    # Get the account number digits
    my @acc = get_acc_array($self->{account_no});
    # Get the branch number digits
    my @branch = get_acc_array($self->{branch});
    # Get the suffix
    my $suff = $self->{suffix};
    # Values to multiply the branch digits with
    my @vals = (6, 3, 7, 9);
    # Values to multiply the account digits with
    my @vals2 = (0, 10, 5, 8, 4, 2, 1);
    my $res = 0;
    
    # Validate the suffix
    if (length($suff) == 2) {
	# Do the multiplications 
	# Branch
	for (my $i = 0; $i < scalar(@vals); $i++) {
	    $res += ($branch[$i] * $vals[$i]);
 	}
	# Account
	for (my $i = 0; $i < scalar(@vals2); $i++) {
	    $res += ($acc[$i] * $vals2[$i]);
 	}

	# Debugging
	$self->{res} = $res;

	# Mod the result with 11
        #$res = ($res / 11) - int($res / 11);
	$res = $res % 11;
    } else {
	# The suffix was not 2 digits, so error
	$self->{error} = 4;
	$self->{error_string} = "Invalid suffix: $suff";
        return 0;
    }

    # If the result was 0 the the account number is valid
    if ($res == 0) {
        return 1;
    } else {
	# Result was not zero so error
	$self->{error} = 1;
	$self->{error_string} = "Invalid account number: $self->{account_no}";
	return 0;
    }
}

# Return the account number as an array
sub get_acc_array($) {
    my ($acc_no) = @_;
    return split('', $acc_no);
}

# Multiply the two numbers together and add up any extra digits once.
sub multi_add($$) {
    my ($a, $b) = @_;
    my $prod = $a * $b;
    my $res = 0;
    my @nums = split('', $prod);

    foreach my $c (@nums) {
	$res += $c;
    }
    return $res;
}

# Multiply the two numbers together and add up any extra digits
# until you have only one digit.
sub multi_add2($$) {
    my ($a, $b) = @_;
    my $prod = $a * $b;
    my $res = $prod;
    my @nums = split('', $prod);
    while($#nums >= 1) {
	$res = 0;
	foreach my $c (@nums) {
	    $res += $c;
	}
	@nums = split('', $res);
    }
    return $res;
}
1;

=head1 DISCLAIMER

This program is distributed in the hope that it will be useful,
but B<without any warranty>; without even the implied warranty of
B<merchantability> or B<fitness for a particular purpose>.

But do let us know if it gives you any problems.

=head1 AUTHORS

    Becky Alcorn, Unisolve Pty Ltd
    Simon Taylor, Unisolve Pty Ltd
    John Bolland, Mainzeal Property and Construction Ltd

Copyright 2002, Unisolve Pty Ltd All rights reserved

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Address bug reports and comments to: simon@unisolve.com.au

=head1 SEE ALSO

Business::CreditCard

=cut

__END__

#------------------------------------------------------------------------------
# $Log: NZ.pm,v $
# Revision 1.4  2003/01/07 00:29:49  simon
# Amended the location of much of the pod and updated some of the content as
# well.
#
# Revision 1.3  2002/11/12 02:38:01  becky
# Minor modifications on site to do with bank 33 being added
#
# Revision 1.0  2002/11/07 03:43:13  simon
# Initial revision
#
