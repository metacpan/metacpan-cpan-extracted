package CLDR::Number::Format::Percent;

use v5.8.1;
use utf8;
use Carp;
use CLDR::Number::Constant qw( $P );

use Moo;
use namespace::clean;

our $VERSION = '0.19';

with qw( CLDR::Number::Role::Format );

has permil => (
    is      => 'rw',
    coerce  => sub { $_[0] ? 1 : 0 },
    default => 0,
);

has percent_sign => (
    is => 'rw',
);

has permil_sign => (
    is => 'rw',
);

has _pattern_type => (
    is      => 'ro',
    default => 'percent',
);

after _trigger_locale => sub {
    my ($self) = @_;

    $self->_build_signs(qw{ percent_sign permil_sign });
};

sub BUILD {}

sub format {
    my ($self, $num) = @_;
    my ($factor, $sign);

    $num = $self->_validate_number(format => $num);
    return undef unless defined $num;

    if ($self->permil) {
        $factor = 1_000;
        $sign   = $self->permil_sign;
    }
    else {
        $factor = 100;
        $sign   = $self->percent_sign;
    }

    my $format = $self->_format_number($num * $factor);
    $format =~ s{$P}{$sign};

    return $format;
}

1;

__END__

=encoding UTF-8

=head1 NAME

CLDR::Number::Format::Percent - Localized percent formatter using the Unicode CLDR

=head1 VERSION

This document describes CLDR::Number::Format::Percent v0.19, built with Unicode
CLDR v29.

=head1 SYNOPSIS

    # either
    use CLDR::Number::Format::Percent;
    $perf = CLDR::Number::Format::Percent->new(locale => 'tr');

    # or
    use CLDR::Number;
    $cldr = CLDR::Number->new(locale => 'tr');
    $perf = $cldr->percent_formatter;

    # when locale is 'tr' (Turkish)
    say $perf->format(0.05);  # '%5'

    # when locale is 'ar' (Arabic)
    say $perf->format(0.05);  # '٥٪'

    # when locale is 'fr' (French)
    say $perf->format(0.05);  # '5 %'

    $perf->permil(1);         # per mil
    say $perf->format(0.05);  # '50 ‰'

=head1 DEPRECATION

Using the C<locale> method as a setter is deprecated. In the future the object’s
locale will become immutable. Please see
L<issue #38|https://github.com/patch/cldr-number-pm5/issues/38> for details and
to submit comments or concerns.

=head1 DESCRIPTION

Localized percent formatter using the Unicode Common Locale Data Repository
(CLDR).

=head2 Methods

=over

=item format

Accepts a number and returns a formatted percent as a character string,
localized for the current locale. If the B<permil> attribute is true, formats as
I<per mil> instead of I<percent>.

=back

=head2 Attributes

The common attributes B<locale>, B<default_locale>, B<numbering_system>,
B<decimal_sign>, B<group_sign>, B<plus_sign>, B<minus_sign>, and B<cldr_version>
are described under L<common attributes in
CLDR::Number|CLDR::Number/"Common Attributes">. All attributes described here
other than B<permil> have defaults that change depending on the current
B<locale>. All string attributes are expected to be character strings, not byte
strings.

=over

=item permil

Default: false (C<0>)

=item percent_sign

Examples: C<%> (percent sign) for all locales

=item permil_sign

Examples: C<‰> (per mille sign) for B<root> and almost all locales

=item pattern

Examples: C<#,##0%> for B<root>, B<en>; C<#,##0 %> for B<de>, B<fr>;
C<#,##,##0%> for B<hi>, B<bn>, B<en-IN>, and other locales of the Indian
subcontinent

=item minimum_integer_digits

Examples: C<1> for all locales

=item minimum_fraction_digits

Examples: C<0> for all locales

=item maximum_fraction_digits

Examples: C<0> for all locales

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
