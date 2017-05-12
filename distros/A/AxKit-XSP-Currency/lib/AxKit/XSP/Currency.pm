# $Id: /local/CPAN/AxKit-XSP-Currency/lib/AxKit/XSP/Currency.pm 1486 2008-03-08T22:00:13.791163Z claco  $
package AxKit::XSP::Currency;
use strict;
use warnings;
use vars qw($VERSION $NS @EXPORT_TAGLIB);
use base 'Apache::AxKit::Language::XSP::TaglibHelper';
use Locale::Currency::Format;
use Finance::Currency::Convert::WebserviceX;

$VERSION = '0.13000';
$NS  = 'http://today.icantfocus.com/CPAN/AxKit/XSP/Currency';

@EXPORT_TAGLIB = (
    'format($price;$code,$options)',
    'symbol(;$code,$options)',
    'convert($price,$from,$to)',
);

my $cc = Finance::Currency::Convert::WebserviceX->new();
my %codes;

sub format {
    my ($price, $code, $options) = @_;

    $code    ||= 'USD';
    $options ||= 'FMT_SYMBOL';

    eval '$options = ' . $options;

    die "Currency code $code is invalid or unknown" unless _valid_code($code);

    return _to_utf8(currency_format($code, $price, $options));
};

sub symbol {
    my ($code, $options) = @_;

    $code    ||= 'USD';
    $options ||= 'SYM_UTF';

    eval '$options = ' . $options;

    die "Currency code $code is invalid or unknown" unless _valid_code($code);

    return _to_utf8(currency_symbol($code, $options));
};

sub convert {
    my ($price, $from, $to) = @_;

    $from ||= 'USD';

    die "Currency code $from/$to is invalid or unknown"  unless
        _valid_code($from) && _valid_code($to);

    return $cc->convert($price, $from, $to);
};

sub _to_utf8 {
    my $value = shift;

    if ($] >= 5.008) {
        require utf8;
        utf8::upgrade($value);
    };

    return $value;
};

sub _valid_code {
    my $code = uc(shift);

    eval 'use Locale::Currency';
    if (!$@) {
        if (! keys %codes) {
            %codes = map {uc($_) => uc($_)} all_currency_codes();
        };
        return exists $codes{$code};
    }

    return $code =~ /^[A-Z]{3}$/;
};

1;
__END__


=head1 NAME

AxKit::XSP::Currency - Currency formatting and conversion taglib

=head1 SYNOPSIS

Add this taglib to AxKit in your http.conf or .htaccess:

    AxAddXSPTaglib AxKit::XSP::Currency

Add the namespace to your XSP file and use the tags:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:currency="http://today.icantfocus.com/CPAN/AxKit/XSP/Currency"
    >

    <currency:format code="USD" options="FMT_STANDARD">19.5</currency:format>

    <currency:format>
        <currency:code>USD</currency:code>
        <currency:options>FMT_HTML</currency:options>
        <currency:price>10.95</currenct:price>
    </currency:format>

    <price><currency:symbol/>10.92</price>

=head1 DESCRIPTION

This tag library provides an interface to format and convert currency values
within XSP pages.

=head1 CHANGES

As of version C<0.10>, the B<defaults have changed>. If no C<options> are specified for
C<symbol>, the default is now C<SYM_UTF> instead of C<SYM_HTML>. If no
C<options> are specified for C<format>, C<FMT_SYMBOL> is used instead of C<FMT_HTML>.

=head1 TAG HIERARCHY

    <currency:format code="USD|CAD|..." options="FMT_STANDARD|FMT_COMMON|..." price="10.95">
        <currency:code></currency:code>
        <currency:options></currency:options>
        <currency:price>10.95</currency:price>
        <convert:price>
            <currency:convert from="USD|CAD|JPY|..." price="10.95" to="CAD|JPY|...">
                <currency:from></currency:from>
                <currency:price</currency:price>
                <currency:to></currency:to>
            </currency:convert>
        </convert:price>
    </currency:format>
    <currency:symbol code="USD|CAD|..." options="SYM_HTML|SYM_UTF">
        <currency:code></currency:code>
        <currency:options></currency:options>
    </currency:symbol>
    <currency:convert from="USD|CAD|JPY|..." price="10.95" to="CAD|JPY|...">
        <currency:from></currency:from>
        <currency:price</currency:price>
        <currency:to></currency:to>
    </currency:convert>

=head1 TAG REFERENCE

=head2 <currency:format>

Given a price, usually in decimal form, format returns a formatted price using
the various options in C<Locale::Currency::Format>.

    <currency:format>
        <currency:price>10.9</currency:price>
    </currency:format>  # prints &amp;#x0024;10.50

The C<format> tag has three available attributes to control the output:

=over

=item code

This is the 3 letter currency code used to specify the currency in use.
The C<code> attribute can also be specified using a child tag instead:

    <currency:format>
        <currency:code>USD</currency:code>
    </currency:format>

C<USD> is used as the default if no currency code is specified.
See C<Locale::Currency::Format> and C<Locale::Currencty> for all of the
available currency codes.

If C<Locale::Currency> is installed, it will verify the 3 letter code is actually
a valid currency code and die if it is not, otherwise it simply checks that
the code conforms to:

    /^[A-Z]{3}$/

=item options

This is a string containing the formatting options to be used to specify
the desired output format. The C<options> attribute can also be specified
using a child tag instead:

    <currency:format>
        <currency:options>FMT_STANDARD | FMT_NOZEROS</currency:options>
    </currency:format>

C<FMT_SYMBOL> is used as the default if no options are specified.
See C<Locale::Currency::Format> for all of the available format options.

=item price

This is the price to be formatted. While it can be passed as an attribute,
the more common usage will be as a child tag:

    <currency:format>
        <currency:price>19.95</currency:price>
    </currency:format>

You can also next a C<convert> tag inside of C<price> to format the results
of a currency conversion:

    <convert:price>
        <currency:convert from="USD|CAD|JPY|..." price="10.95" to="CAD|JPY|...">
            <currency:from></currency:from>
            <currency:price</currency:price>
            <currency:to></currency:to>
        </currency:convert>
    </convert:price>

=back

=head2 <currency:symbol>

Returns the monetary symbol for the specified currency code.

    <currency:symbol code="USD"/>   # prints $

The C<symbol> tag has two available attributes to control the output:

=over

=item code

This is the 3 letter currency code used to specify the currency in use.
The C<code> attribute can also be specified using a child tag instead:

    <currency:symbol>
        <currency:code>USD</currency:code>
    </currency:symbol>

C<USD> is used as the default if no currency code is specified.
See C<Locale::Currency::Format> for all of the available currency codes.

If C<Locale::Currency> is installed, it will verify the 3 letter code is actually
a valid currency code and die if it is not, otherwise it simply checks that
the code conforms to:

    /^[A-Z]{3}$/

=item options

This is a string containing the formatting options to be used to specify
the desired output format. The C<options> attribute can also be specified
using a child tag instead:

    <currency:symbol code="USD">
        <currency:options>SYM_HTML|SYM_UTF</currency:options>
    </currency:symbol>

C<SYM_UTF> is used as the default if no options are specified.
See C<Locale::Currency::Format> for all of the available format options.

=back

=head2 <currency:convert>

Converts a price from one currency to another using C<Finance::Currency::Convert::WebserviceX>.

    <currency:convert from="USD|CAD|JPY|..." price="10.95" to="CAD|JPY|...">
        <currency:from></currency:from>
        <currency:price</currency:price>
        <currency:to></currency:to>
    </currency:convert>

The C<convert> tag has three available attributes to control the output:

=over

=item from

This is the 3 letter currency code used to specify the currency in use.
The C<from> attribute can also be specified using a child tag instead:

    <currency:convert>
        <currency:from>USD</currency:from>
    </currency:convert>

C<USD> is used as the default if no currency code is specified.

If C<Locale::Currency> is installed, it will verify the 3 letter code is actually
a valid currency code and die if it is not, otherwise it simply checks that
the code conforms to:

    /^[A-Z]{3}$/

See C<Locale::Currency> for all of the available currency codes.

=item price

This is the price to be formatted. While it can be passed as an attribute,
the more common usage will be as a child tag:

    <currency:convert>
        <currency:price>19.95</currency:price>
    </currency:convert>

=item to

This is the 3 letter currency code used to specify the currency in use.
The C<to> attribute can also be specified using a child tag instead:

    <currency:convert>
        <currency:to>USD</currency:to>
    </currency:convert>

If C<Locale::Currency> is installed, it will verify the 3 letter code is actually
a valid currency code and die if it is not, otherwise it simply checks that
the code conforms to:

    /^[A-Z]{3}$/

See C<Locale::Currency> for all of the available currency codes.

=back

=head1 SEE ALSO

L<Locale::Currency::Format>, L<Locale::Currency>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
