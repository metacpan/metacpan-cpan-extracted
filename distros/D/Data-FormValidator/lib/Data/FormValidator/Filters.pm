#    Filters.pm - Common filters for use in Data::FormValidator.
#    This file is part of Data::FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#    Maintainer: Mark Stosberg <mark@summersault.com>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.

package Data::FormValidator::Filters;
use Exporter 'import';
use strict;

our $VERSION = 4.88;

our @EXPORT_OK = qw(
    filter_alphanum
    filter_decimal
    filter_digit
    filter_dollars
    filter_integer
    filter_lc
    filter_neg_decimal
    filter_neg_integer
    filter_phone
    filter_pos_decimal
    filter_pos_integer
    filter_quotemeta
    filter_sql_wildcard
    filter_strip
    filter_trim
    filter_uc
    filter_ucfirst
    FV_split
    FV_replace
);

our %EXPORT_TAGS = (
    filters => \@EXPORT_OK,
);

sub DESTROY {}

=pod

=head1 NAME

Data::FormValidator::Filters - Basic set of filters available in an Data::FormValidator profile.

=head1 SYNOPSIS

    use Data::FormValidator;

    %profile = (
        filters => 'trim',
        ...
    );

    my $results = Data::FormValidator->check(  \%data, \%profile );

=head1 DESCRIPTION

These are the builtin filters which may be specified as a name in the
I<filters>, I<field_filters>, and I<field_filter_regexp_map> parameters of the
input profile.

Filters are applied as the first step of validation, possibly modifying a copy
of the validation before any constraints are checked.

=head1 RECOMMENDED USE

As a long time maintainer and user of Data::FormValidator, I recommend that
filters be used with caution. They are immediately modifying the input
provided, so the original data is lost. The few I recommend include C<trim>,
which removes leading and trailing whitespace. I have this turned on by default
by using L<CGI::Application::Plugin::ValidateRM>. It's also generally safe to use
the C<lc> and C<uc> filters if you need that kind of data transformation.

Beyond simple filters, I recommend transforming the C<"valid"> hash returned
from validation if further changes are needed.

=head1 PROCEDURAL INTERFACE

You may also call these functions directly through the
procedural interface by either importing them directly or importing the whole
I<:filters> group. For example, if you want to access the I<trim> function
directly, you could either do:

    use Data::FormValidator::Filters (qw/filter_trim/);
    # or
    use Data::FormValidator::Filters (qw/:filters/);

    $string = filter_trim($string);

Notice that when you call filters directly, you'll need to prefix the filter name with
"filter_".

=head1 THE FILTERS

=head2 FV_split

  use Data::FormValidator::Filters qw(FV_split);

  # Validate every e-mail in a comma separated list

  field_filters => {
     several_emails  => FV_split(qr/\s*,\s*/),

     # Any pattern that can be used by the 'split' builtin works.
     tab_sep_field   => FV_split('\t'),
  },
  constraint_methods => {
    several_emails => email(),
  },

With this filter, you can split a field into multiple values. The constraint for
the field will then be applied to every value.

This filter has a different naming convention because it is a higher-order
function.  Rather than returning a value directly, it returns a code reference
to a standard Data::FormValidator filter.

After successfully being validated the values will appear as an arrayref.

=cut

sub FV_split {
    my $splitter = shift || die "nothing to split on!";
    return sub {
        my $value = shift;
        return undef unless defined $value;
        my @a = split $splitter, $value;
        return \@a;
    };
}

=head2 FV_replace

  use Data::FormValidator::Filters qw(FV_replace);

  field_filters => {
     first_name   => FV_replace(qr/Mark/,'Don'),
  },

FV_replace is a shorthand for writing simple find-and-replace filters.
The above filter would be translated to this:

 sub { my $v = shift; $v =~ s/Mark/Don/; $v }

For more complex filters, just write your own.

=cut

sub FV_replace {
    my ($find,$replace) = @_;
    return sub {
        my $v = shift;
        $v =~ s/$find/$replace/;
        return $v;
    };
}

=head2 trim

Remove white space at the front and end of the fields.

=cut

sub filter_trim {
    my $value = shift;
    return unless defined $value;

    # Remove whitespace at the front
    $value =~ s/^\s+//o;

    # Remove whitespace at the end
    $value =~ s/\s+$//o;

    return $value;
}

=pod

=head2 strip

Runs of white space are replaced by a single space.

=cut

sub filter_strip {
    my $value = shift;
    return unless defined $value;

    # Strip whitespace
    $value =~ s/\s+/ /g;

    return $value;
}

=pod

=head2 digit

Remove non digits characters from the input.

=cut

sub filter_digit {
    my $value = shift;
    return unless defined $value;

    $value =~ s/\D//g;

    return $value;
}

=pod

=head2 alphanum

Remove non alphanumeric characters from the input.

=cut

sub filter_alphanum {
    my $value = shift;
    return unless defined $value;
    $value =~ s/\W//g;
    return $value;
}

=pod

=head2 integer

Extract from its input a valid integer number.

=cut

sub filter_integer {
    my $value = shift;
    return unless defined $value;
    $value =~ tr/0-9+-//dc;
    ($value) =~ m/([-+]?\d+)/;
    return $value;
}

=pod

=head2 pos_integer

Extract from its input a valid positive integer number.

Bugs: This filter won't extract "9" from "a9+", it will instead extract "9+"

=cut

sub filter_pos_integer {
    my $value = shift;
    return unless defined $value;
    $value =~ tr/0-9+//dc;
    ($value) =~ m/(\+?\d+)/;
    return $value;
}

=pod

=head2 neg_integer

Extract from its input a valid negative integer number.

Bugs: This filter will currently filter the case of "a9-" to become "9-",
which it should leave it alone.

=cut

sub filter_neg_integer {
    my $value = shift;
    return unless defined $value;
    $value =~ tr/0-9-//dc;
    ($value) =~ m/(-\d+)/;
    return $value;
}

=pod

=head2 decimal

Extract from its input a valid decimal number.

Bugs: Given "1,000.23", it will currently return "1.000.23"

=cut

sub filter_decimal {
    my $value = shift;
    return unless defined $value;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/([-+]?\d+\.?\d*)/;
    return $value;
}

=pod

=head2 pos_decimal

Extract from its input a valid positive decimal number.

Bugs: Given "1,000.23", it will currently return "1.000.23"

=cut

sub filter_pos_decimal {
    my $value = shift;
    return unless defined $value;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.+//dc;
    ($value) =~ m/(\+?\d+\.?\d*)/;
    return $value;
}

=pod

=head2 neg_decimal

Extract from its input a valid negative decimal number.

Bugs: Given "1,000.23", it will currently return "1.000.23"

=cut

sub filter_neg_decimal {
    my $value = shift;
    return unless defined $value;
    # This is a localization problem, but anyhow...
    $value =~ tr/,/./;
    $value =~ tr/0-9.-//dc;
    ($value) =~ m/(-\d+\.?\d*)/;
    return $value;
}

=pod

=head2 dollars

Extract from its input a valid number to express dollars like currency.

Bugs: This filter won't currently remove trailing numbers like "1.234".

=cut

sub filter_dollars {
    my $value = shift;
    return unless defined $value;
    $value =~ tr/,/./;
    $value =~ tr/0-9.+-//dc;
    ($value) =~ m/(\d+\.?\d?\d?)/;
    return $value;
}

=pod

=head2 phone

Filters out characters which aren't valid for an phone number. (Only
accept digits [0-9], space, comma, minus, parenthesis, period and pound [#].)

=cut

sub filter_phone {
    my $value = shift;
    return unless defined $value;
    $value =~ s/[^\d,\(\)\.\s,\-#]//g;
    return $value;
}

=pod

=head2 sql_wildcard

Transforms shell glob wildcard (*) to the SQL like wildcard (%).

=cut

sub filter_sql_wildcard {
    my $value = shift;
    return unless defined $value;
    $value =~ tr/*/%/;
    return $value;
}

=pod

=head2 quotemeta

Calls the quotemeta (quote non alphanumeric character) builtin on its
input.

=cut

sub filter_quotemeta {
    return unless defined $_[0];
    quotemeta $_[0];
}

=pod

=head2 lc

Calls the lc (convert to lowercase) builtin on its input.

=cut

sub filter_lc {
    return unless defined $_[0];
    lc $_[0];
}

=pod

=head2 uc

Calls the uc (convert to uppercase) builtin on its input.

=cut

sub filter_uc {
    return unless defined $_[0];
    uc $_[0];
}

=pod

=head2 ucfirst

Calls the ucfirst (Uppercase first letter) builtin on its input.

=cut

sub filter_ucfirst {
    return unless defined $_[0];
    ucfirst $_[0];
}


1;

__END__

=head1 SEE ALSO

=over 4

=item o

 L<Data::FormValidator>

=item o

 L<Data::FormValidator::Constraints>

=item o

 L<Data::FormValidator::Filters::Image> - shrink incoming image uploads

=back

=head1 AUTHOR

 Author:  Francis J. Lacoste <francis.lacoste@iNsu.COM>
 Maintainer: Mark Stosberg <mark@summersault.com>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut

