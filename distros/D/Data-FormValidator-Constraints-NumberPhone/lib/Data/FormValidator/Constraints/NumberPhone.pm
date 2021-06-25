package Data::FormValidator::Constraints::NumberPhone;

###############################################################################
# Required inclusions;
use strict;
use warnings;
use Number::Phone;

###############################################################################
# Version number.
our $VERSION = '0.05';

###############################################################################
# Allow our methods to be exported.
use base qw(Exporter);
use vars qw(@EXPORT_OK);
our @EXPORT_OK = qw(
    FV_american_phone
    FV_telephone
);

###############################################################################
# Subroutine:   FV_american_phone()
###############################################################################
# Creates a constraint closure that returns true if the constrained value
# appears to be a valid North American telephone number (Canada, or US)
sub FV_american_phone {
    return FV_telephone(qw( CA US ));
}

###############################################################################
# Subroutine:   FV_telephone(@countries)
# Creates a constraint closure that returns true if the constrained value
# appears to be a valid telephone number.
#
# REQUIRES a list of Country Codes (e.g. "CA", "US", "UK"), to specify which
# countries should be considered valid.  By default, *NO* countries are
# considered valid (and thus, no numbers are considered valid by default).
sub FV_telephone {
    my @countries = @_;

    return sub {
        my $dfv = shift;
        my $val = $dfv->get_current_constraint_value;

        # No country?  Not valid; you didn't tell us what to validate it for.
        return 0 unless @countries;

        # Add leading "+" if it looks like we've got a long distance prefix
        $val = "+$val" if ($val =~ /^\s*1/);

        # Try to instantiate the telephone number using any of the provided
        # Countries.
        foreach my $country (@countries) {
            my $ph = Number::Phone->new($country => $val);
            next unless $ph;
            next unless $ph->is_valid;
            next unless ($ph->country && (uc($ph->country) eq uc($country)));
            return 1;
        }

        return 0;
    };
}

1;

=head1 NAME

Data::FormValidator::Constraints::NumberPhone - Data constraints, using Number::Phone

=head1 SYNOPSIS

  use Data::FormValidator::Constraints::NumberPhone qw(FV_american_phone);

  constraint_methods => {
      phone        => FV_american_phone(),
      canada_phone => FV_american_phone(qw( CA )),
  },

=head1 DESCRIPTION

This module implements methods to help validate data using
C<Data::FormValidator> and C<Number::Phone>.

=head1 METHODS

=over

=item FV_american_phone()

Creates a constraint closure that returns true if the constrained value
appears to be a valid North American telephone number (Canada, or US)

=item FV_telephone(@countries)

Creates a constraint closure that returns true if the constrained value
appears to be a valid telephone number.

REQUIRES a list of Country Codes (e.g. "CA", "US", "UK"), to specify which
countries should be considered valid. By default, *NO* countries are
considered valid (and thus, no numbers are considered valid by default).

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2012, Graham TerMarsch.  All Rights Reserved.

=head1 SEE ALSO

=over

=item L<Data::FormValidator>

=item L<Number::Phone>

=back

=cut
