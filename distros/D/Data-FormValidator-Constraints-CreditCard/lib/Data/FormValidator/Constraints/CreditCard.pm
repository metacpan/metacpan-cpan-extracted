package Data::FormValidator::Constraints::CreditCard;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use Business::CreditCard qw();

###############################################################################
# Version number.
###############################################################################
our $VERSION = '0.04';

###############################################################################
# Allow our methods to be exported.
###############################################################################
use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT_OK %EXPORT_TAGS );
@EXPORT_OK = qw(
    FV_cc_number
    FV_cc_type
    FV_cc_expiry
    FV_cc_expiry_month
    FV_cc_expiry_year
    );
%EXPORT_TAGS = (
    'all'   => [@EXPORT_OK],
    );

###############################################################################
# Subroutine:   FV_cc_number()
###############################################################################
# Creates a constraint closure that returns true if the constrained value
# appears to be a valid credit card number.
#
# NOTE: "appears to be a valid credit card number" ONLY means that the number
# appears to be valid and has passed the checksum test; -NO- tests have been
# performed to verify that this is actually a real/valid credit card number.
###############################################################################
sub FV_cc_number {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return Business::CreditCard::validate($val);
    };
}

###############################################################################
# Subroutine:   FV_cc_type(@set)
###############################################################################
# Creates a constraint closure that returns true if the constrained value
# appears to be a credit card of one of the types listed in the given '@set'.
# The '@set' can be provided as either a list of scalars (which are compared
# using the 'eq' operator), or as a list of regular expressions.
#
# For more information on the actual card types that can be checked for, please
# refer to the information for the 'cardtype()' method in
# 'Business::CreditCard'.
###############################################################################
sub FV_cc_type {
    my (@set) = @_;
    return sub {
        my $dfv  = shift;
        my $val  = $dfv->get_current_constraint_value();
        my $type = Business::CreditCard::cardtype($val);
        foreach my $elem (@set) {
            if (ref($elem) eq 'Regexp') {
                return 1 if ($type =~ $elem);
            }
            else {
                return 1 if ($type eq $elem);
            }
        }
        return;
    }
}

###############################################################################
# Subroutine:   FV_cc_expiry()
###############################################################################
# Creates a constraint closure that returns true if the constrained value
# appears to be a valid credit card expiry date; correct integer values for
# year/month, with the date not being in the past.
#
# Accepted formats include "MM/YY" and "MM/YYYY".
#
# NOTE: use of this method requires that the full credit card expiry date be
# present in a single field; no facilities are provided for gathering the
# month/year data from two separate fields.
###############################################################################
sub FV_cc_expiry {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        my ($month, $year) = split('/', $val);
        return if ((!defined $month) or (!defined $year));
        # verify each field individually
        return if (!_match_cc_expiry_month($month));
        return if (!_match_cc_expiry_year($year));
        # verify that date is not in the past
        my @now = localtime();
        $year = _windowize_year($year);
        return if ($year == ($now[5]+1900) and $month <= ($now[4]+1));
        # looks good!
        return "$month/$year";
    }
}

sub _windowize_year {
    my $year = shift;
    if ($year < 1900) {
        $year += ($year < 70) ? 2000 : 1900;
    }
    return $year;
}

sub _match_cc_expiry_month {
    my $val = shift;
    return if ($val =~ /\D/);   # only contain numerics
    return if ($val < 1);       # can't be <1
    return if ($val > 12);      # can't be >12
    return $val;
}

sub _match_cc_expiry_year {
    my $val = shift;
    my $now = (localtime)[5] + 1900;
    return if ($val =~ /\D/);   # only contain numerics
    $val = _windowize_year($val);
    return if ($val < $now);    # can't be before this year
    return $val;
}

###############################################################################
# Subroutine:   FV_cc_expiry_month()
###############################################################################
# Creates a constraint closure that returns true if the constrained value
# appears to be a valid credit card expiry month; an integer in the range of
# "1-12".
###############################################################################
sub FV_cc_expiry_month {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return _match_cc_expiry_month($val);
    }
}

###############################################################################
# Subroutine:   FV_cc_expiry_year()
###############################################################################
# Creates a constraint closure that returns true if the constrained value
# appears to be a valid credit card expiry year; an integer value for a year,
# not in the past.
#
# Expiry years can be provided as either "YY" or "YYYY".  When using the
# two-digit "YY" format, the year is considered to be part of the sliding
# window 1970-2069.
###############################################################################
sub FV_cc_expiry_year {
    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value();
        return _match_cc_expiry_year($val);
    }
}

1;

=for stopwords MM YY YYYY checksum

=head1 NAME

Data::FormValidator::Constraints::CreditCard - Data constraints, using Business::CreditCard

=head1 SYNOPSIS

  use Data::FormValidator::Constraints::CreditCard qw(:all);

  constraint_methods => {
      cc_number     => [
        # number is syntactically valid
        FV_cc_number(),

        # verify type, by value
        FV_cc_type(qw(Visa MasterCard)),

        # verify type, by regex
        FV_cc_type(qr/visa|mastercard/i),
        ],

      # expiry month is within valid range
      cc_exp_mon    => FV_cc_expiry_month(),

      # expiry year is not in the past
      cc_exp_year   => FV_cc_expiry_year(),

      # full expiry date is not in the past
      cc_expiry     => FV_cc_expiry(),
  },

=head1 DESCRIPTION

C<Data::FormValidator::Constraints::CreditCard> provides several methods that
can be used to generate constraint closures for use with C<Data::FormValidator>
for the purpose of validating credit card numbers and expiry dates, using
C<Business::CreditCard>.

=head1 METHODS

=over

=item FV_cc_number()

Creates a constraint closure that returns true if the constrained value
appears to be a valid credit card number.

NOTE: "appears to be a valid credit card number" ONLY means that the number
appears to be valid and has passed the checksum test; -NO- tests have been
performed to verify that this is actually a real/valid credit card number.

=item FV_cc_type(@set)

Creates a constraint closure that returns true if the constrained value
appears to be a credit card of one of the types listed in the given
C<@set>. The C<@set> can be provided as either a list of scalars (which are
compared using the C<eq> operator), or as a list of regular expressions.

For more information on the actual card types that can be checked for,
please refer to the information for the C<cardtype()> method in
C<Business::CreditCard>.

=item FV_cc_expiry()

Creates a constraint closure that returns true if the constrained value
appears to be a valid credit card expiry date; correct integer values for
year/month, with the date not being in the past.

Accepted formats include "MM/YY" and "MM/YYYY".

NOTE: use of this method requires that the full credit card expiry date be
present in a single field; no facilities are provided for gathering the
month/year data from two separate fields.

=item FV_cc_expiry_month()

Creates a constraint closure that returns true if the constrained value
appears to be a valid credit card expiry month; an integer in the range of
"1-12".

=item FV_cc_expiry_year()

Creates a constraint closure that returns true if the constrained value
appears to be a valid credit card expiry year; an integer value for a year,
not in the past.

Expiry years can be provided as either "YY" or "YYYY". When using the
two-digit "YY" format, the year is considered to be part of the sliding
window 1970-2069.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2008, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

L<Data::FormValidator>,
L<Business::CreditCard>.

=cut
