package CLDR::Number::Format::Decimal;

use v5.8.1;
use utf8;
use Carp;

use Moo;
use namespace::clean;

our $VERSION = '0.19';

with qw( CLDR::Number::Role::Format );

has _pattern_type => (
    is      => 'ro',
    default => 'decimal',
);

sub BUILD {}

sub format {
    my ($self, $num) = @_;

    $num = $self->_validate_number(format => $num);
    return undef unless defined $num;

    return $self->_format_number($num);
}

1;

__END__

=encoding UTF-8

=head1 NAME

CLDR::Number::Format::Decimal - Localized decimal formatter using the Unicode CLDR

=head1 VERSION

This document describes CLDR::Number::Format::Decimal v0.19, built with Unicode
CLDR v29.

=head1 SYNOPSIS

    # either
    use CLDR::Number::Format::Decimal;
    $decf = CLDR::Number::Format::Decimal->new(locale => 'es');

    # or
    use CLDR::Number;
    $cldr = CLDR::Number->new(locale => 'es');
    $decf = $cldr->decimal_formatter;

    # when locale is 'es' (Spanish)
    say $decf->format(1234.5);  # '1234,5'

    # when locale is 'es-MX' (Mexican Spanish)
    say $decf->format(1234.5);  # '1,234.5'

    # when locale is 'ar' (Arabic)
    say $decf->format(1234.5);  # '١٬٢٣٤٫٥'

    # when locale is 'bn' (Bengali)
    say $curf->format(123456);  # '১,২৩,৪৫৬'

=head1 DEPRECATION

Using the C<locale> method as a setter is deprecated. In the future the object’s
locale will become immutable. Please see
L<issue #38|https://github.com/patch/cldr-number-pm5/issues/38> for details and
to submit comments or concerns.

=head1 DESCRIPTION

Localized decimal formatter using the Unicode Common Locale Data Repository
(CLDR).

=head2 Methods

Any argument that Perl can treat as a number is supported, including infinity,
negative infinity, and NaN, which are all localized appropriately. All methods
return character strings, not encoded byte strings.

=over

=item format

Accepts a number and returns a formatted decimal, localized for the current
locale.

=item at_least

Accepts a number and returns a formatted decimal for at least the supplied
number.

    say $decf->at_least(100);  # '100+'

=item range

Accepts two numbers and returns a formatted range of decimals.

    say $decf->range(1, 10);  # '1–10'

=back

=head2 Attributes

The common attributes B<locale>, B<default_locale>, B<numbering_system>,
B<decimal_sign>, B<group_sign>, B<plus_sign>, B<minus_sign>, and B<cldr_version>
are described under L<common attributes in
CLDR::Number|CLDR::Number/"Common Attributes">. All attributes described here
have defaults that change depending on the current B<locale>. All string
attributes are expected to be character strings, not byte strings.

=over

=item pattern

Examples: C<#,##0.###> for B<root>, B<en>, and most locales; C<#,##,##0.###> for
B<hi>, B<bn>, B<en-IN>, and other locales of the Indian subcontinent

=item minimum_integer_digits

Examples: C<1> for all locales

=item minimum_fraction_digits

Examples: C<0> for all locales

=item maximum_fraction_digits

Examples: C<3> for B<root> and almost all locales

=item primary_grouping_size

Examples: C<3> for B<root> and almost all locales

Not used when value is C<0>.

=item secondary_grouping_size

Examples: C<0> for B<root>, B<en>, and most locales; C<2> for B<hi>, B<bn>,
B<en-IN>, and other locales of the Indian subcontinent

Not used when value is C<0>.

=item minimum_grouping_digits

Examples: C<1> for B<root>, B<en>, and most locales; C<2> for C<es> (excluding
C<es-419>), C<pt-PT>, C<pl>, and several others; C<3> for C<lv> and C<my>

=item rounding_increment

Examples: C<0> for all locales

C<0> and C<1> are treated the same.

=back

=head1 SEE ALSO

L<CLDR::Number>

=head1 AUTHOR

Nova Patch <patch@cpan.org>

This project is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2013–2016 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
