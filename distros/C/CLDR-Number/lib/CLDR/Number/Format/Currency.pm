package CLDR::Number::Format::Currency;

use v5.8.1;
use utf8;
use Carp;
use CLDR::Number::Constant qw( $C );
use CLDR::Number::Data::Currency;

use Moo;
use namespace::clean;

our $VERSION = '0.19';

with qw( CLDR::Number::Role::Format );

has currency_code => (
    is  => 'rw',
    isa => sub {
        croak 'uninitialized value'     if !defined $_[0];
        croak qq{invalid value "$_[0]"} if $_[0] !~ m{ ^ [A-Z]{3} $ }x;
    },
    coerce  => sub { defined $_[0] ? uc $_[0] : $_[0] },
    trigger => 1,
);

has currency_sign => (
    is  => 'rw',
    isa => sub {
        croak "currency_sign is not defined" if !defined $_[0];
    },
);

# TODO: accounting NYI
has accounting => (
    is      => 'rw',
    coerce  => sub { $_[0] ? 1 : 0 },
    default => 0,
);

has cash => (
    is      => 'rw',
    coerce  => sub { $_[0] ? 1 : 0 },
    trigger => 1,
    default => 0,
);

has _pattern_type => (
    is      => 'ro',
    default => 'currency',
);

after _trigger_locale => sub {
    my ($self) = @_;

    if ($self->currency_code) {
        $self->_build_currency_sign;
    }

    if (my $decimal = $self->_get_data(symbol => 'currency_decimal')) {
        $self->decimal_sign($decimal);
    }
};

sub BUILD {}

sub _trigger_currency_code {
    my ($self, $currency_code) = @_;

    $self->_build_currency_sign;
    $self->_trigger_cash;
}

sub _build_currency_sign {
    my ($self) = @_;
    my $data = $CLDR::Number::Data::Currency::LOCALES;
    my $currency_sign;

    return if $self->_has_init_arg('currency_sign');

    for my $locale (@{$self->_locale_inheritance}) {
        next if !exists $data->{$locale} || !exists $data->{$locale}{$self->currency_code};
        $currency_sign = $data->{$locale}{$self->currency_code};
        last;
    }

    $self->currency_sign($currency_sign || $self->currency_code);
}

sub _trigger_cash {
    my ($self) = @_;
    my $currencies = $CLDR::Number::Data::Currency::CURRENCIES;
    my $currency_data
        = $self->currency_code && exists $currencies->{$self->currency_code}
        ? $currencies->{$self->currency_code}
        : $currencies->{DEFAULT};

    if ($self->cash && exists $currency_data->{cash_digits}) {
        $self->minimum_fraction_digits($currency_data->{cash_digits});
        $self->maximum_fraction_digits($currency_data->{cash_digits});
    }
    else {
        $self->minimum_fraction_digits($currency_data->{digits});
        $self->maximum_fraction_digits($currency_data->{digits});
    }

    if ($self->cash && exists $currency_data->{cash_rounding}) {
        $self->rounding_increment($currency_data->{cash_rounding});
    }
    else {
        $self->rounding_increment($currency_data->{rounding});
    }
}

sub format {
    my ($self, $num) = @_;

    $num = $self->_validate_number(format => $num);
    return undef unless defined $num;

    croak 'Missing required attribute: currency_code'
        unless $self->currency_code;

    my $sign   = $self->currency_sign;
    my $format = $self->_format_number($num);

    # spacing before currency sign
    if ($sign =~ m{ ^ \PS }x && $format =~ m{ \d $C }x) {
        $sign = ' ' . $sign;
    }

    # spacing after currency sign
    if ($sign =~ m{ \PS $ }x && $format =~ m{ $C \d }x) {
        $sign .= ' ';
    }

    $format =~ s{$C}{$sign};

    return $format;
}

1;

__END__

=encoding UTF-8

=head1 NAME

CLDR::Number::Format::Currency - Localized currency formatter using the Unicode CLDR

=head1 VERSION

This document describes CLDR::Number::Format::Currency v0.19, built with Unicode
CLDR v29.

=head1 SYNOPSIS

    # either
    use CLDR::Number::Format::Currency;
    $curf = CLDR::Number::Format::Currency->new(
        locale        => 'en',
        currency_code => 'USD',
    );

    # or
    use CLDR::Number;
    $cldr = CLDR::Number->new(locale => 'en');
    $curf = $cldr->currency_formatter(currency_code => 'USD');

    # when locale is 'en' (English) and currency is USD (US dollars)
    say $curf->format(9.99);  # '$9.99'

    # when locale is 'en-CA' (Canadian English) and currency is USD
    say $curf->format(9.99);  # 'US$9.99'

    # when locale is 'fr-CA' (Canadian French) and currency is USD
    say $curf->format(9.99);  # '9,99 $ US'

    # when locale is 'bn' (Bengali) and currency is INR (Indian rupees)
    say $curf->format(123456);  # '১,২৩,৪৫৬.০০₹'

=head1 DEPRECATION

Using the C<locale> method as a setter is deprecated. In the future the object’s
locale will become immutable. Please see
L<issue #38|https://github.com/patch/cldr-number-pm5/issues/38> for details and
to submit comments or concerns.

=head1 DESCRIPTION

Localized currency formatter using the Unicode Common Locale Data Repository
(CLDR).

=head2 Methods

=over

=item format

Accepts a number and returns a formatted currency value as a character string,
using the currency from the B<currency_code> attribute and localized for the
current locale.

=back

=head2 Attributes

The common attributes B<locale>, B<default_locale>, B<numbering_system>,
B<decimal_sign>, B<group_sign>, B<plus_sign>, B<minus_sign>, and B<cldr_version>
are described under L<common attributes in
CLDR::Number|CLDR::Number/"Common Attributes">. All attributes described here
other than B<currency_code> and B<cash> have defaults that change depending on
the current B<locale>. The attributes B<currency_sign>,
B<minimum_fraction_digits>, B<maximum_fraction_digits>, and
B<rounding_increment> also change depending on the B<currency_code> and B<cash>
values. All string attributes are expected to be character strings, not byte
strings.

=over

=item currency_code

Default: none

Valid: ISO 4217 3-letter alphabetic currency codes

Examples: C<EUR> (Euro), C<USD> (US Dollar), C<JPY> (Japanese Yen)

The currency code is case-insensitive and is required in order to call the
B<format> method, but not required to instantiate this formatter object.

=item currency_sign

Default: based on both B<locale> and B<currency_code>

Examples: C<US$> for B<root>, B<en-CA> with B<USD>; C<$> for B<en>, B<de> with
B<USD>; C<$US> for B<fr> with B<USD>; C<USD> for B<es-MX> with B<USD>

=item cash

Default: false (C<0>)

Formatting for cash can be different for some currencies. Setting B<cash> to
true (C<1>) enables cash formatting when different from standard formatting.

=item pattern

Examples: C<¤ #,##0.00> for B<root>; C<¤#,##0.00> for B<en>; C<#,##0.00 ¤> for
B<de>, B<fr>; C<¤ #,##0.00;¤ -#,##0.00> for B<nl>; and many other variations for
different locales

=item minimum_integer_digits

Examples: C<1> for all locales

=item minimum_fraction_digits

Examples: C<2> for most currencies; C<3> for B<BHD>; C<0> for B<JPY> or for
B<TWD> when B<cash> is true

=item maximum_fraction_digits

Examples: C<2> for most currencies; C<3> for B<BHD>; C<0> for B<JPY> or for
B<TWD> when B<cash> is true

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

Examples: C<0> for all currencies; C<5> for B<CAD>, B<CHF> when B<cash> is true

C<0> and C<1> are treated the same.

=back

=head1 SEE ALSO

=over

=item * L<CLDR::Number>

=item * L<CLDR Translation Guidelines: Currency
Symbols|http://cldr.unicode.org/translation/currency-names>

=back

=head1 AUTHOR

Nova Patch <patch@cpan.org>

This project is brought to you by L<Shutterstock|http://www.shutterstock.com/>.
Additional open source projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 COPYRIGHT AND LICENSE

© 2013–2016 Shutterstock, Inc.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
