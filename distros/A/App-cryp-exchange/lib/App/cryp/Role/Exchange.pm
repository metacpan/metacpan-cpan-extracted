package App::cryp::Role::Exchange;

our $DATE = '2018-04-04'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

requires qw(
               new
               list_pairs
               data_native_pair_separator
               data_canonical_currencies
       );

sub data_reverse_canonical_currencies {
    my $self = shift;

    return $self->{_reverse_canonical_currencies}
        if $self->{_reverse_canonical_currencies};

    $self->{_reverse_canonical_currencies} = {
        reverse %{ $self->data_canonical_currencies }
    };
}

sub to_canonical_currency {
    my ($self, $cur) = @_;
    $cur = uc $cur;
    my $cur2 = $self->data_canonical_currencies->{$cur};
    $cur2 // $cur;
}

sub to_native_currency {
    my ($self, $cur) = @_;
    $cur = uc $cur;
    my $cur2 = $self->data_reverse_canonical_currencies->{$cur};
    $cur2 // $cur;
}

sub to_canonical_pair {
    my ($self, $pair) = @_;

    my ($cur1, $cur2) = $pair =~ /(\w+)[\W_](\w+)/
        or die "Invalid pair '$pair'";
    sprintf "%s/%s",
        $self->to_canonical_currency($cur1),
        $self->to_canonical_currency($cur2);
}

sub to_native_pair {
    my ($self, $pair) = @_;

    my ($cur1, $cur2) = $pair =~ /(\w+)[\W_](\w+)/
        or die "Invalid pair '$pair'";
    sprintf "%s%s%s",
        $self->to_native_currency($cur1),
        $self->data_native_pair_separator,
        $self->to_native_currency($cur2);
}

1;
# ABSTRACT: Role for interacting with an exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Role::Exchange - Role for interacting with an exchange

=head1 VERSION

This document describes version 0.001 of App::cryp::Role::Exchange (from Perl distribution App-cryp-exchange), released on 2018-04-04.

=head1 DESCRIPTION

This role describes the common API for interacting with an exchange that all
C<App::cryp::Exchange::*> modules follow.

=head1 ENVELOPED RESULT

All methods, unless specified otherwise, must return enveloped result:

 [$status, $reason, $payload, \%extra]

This result is analogous to an HTTP response; in fact C<$status> mostly uses
HTTP response codes. C<$reason> is analogous to HTTP status message. C<$payload>
is the actual content (optional if C<$status> is error status). C<%extra> is
optional and analogous to HTTP response headers to specify flags or attributes
or other metadata.

Some examples of enveloped result:

 [200, "OK", ["BTC/USD", "ETH/BTC"]]
 [404, "Not found"]

For more details about enveloped result, see L<Rinci::function>.

=head1 PROVIDED METHODS

=head2 to_canonical_currency

Usage:

 $xchg->to_canonical_currency($cur) => str

Convert native currency code to canonical/standardized currency code. Canonical
codes are listed in L<CryptoCurrency::Catalog>.

=head2 to_native_currency

Usage:

 $xchg->to_native_currency($cur) => str

Convert canonical/standardized currency code to exchange-native currency code.
Canonical codes are listed in L<CryptoCurrency::Catalog>.

=head2 to_canonical_pair

Usage:

 $xchg->to_canonical_pair($pair) => str

=head2 to_native_pair

Usage:

 $xchg->to_native_pair($pair) => str

=head1 REQUIRED METHODS

=head2 new

Usage:

 new(%args) => obj

Constructor. Known arguments:

=over

=item * api_key

String. Required.

=item * api_secret

String. Required.

=back

Some specific exchanges might require more credentials or arguments; please
check with the specific drivers.

Method must return object.

=head2 data_native_pair_separator

Should return a single-character string.

=head2 data_canonical_currencies

Should return a hashref, a mapping between exchange-native currency codes to
canonical/standardized currency codes.

=head2 data_reverse_canonical_currencies

Returns hashref, a mapping of canonical/standardized currency codes to exchange
native codes, which is produced by reversing the hash returned by
C</"data_canonical_currencies"> and caching the result in the instance's
C<_reverse_canonical_currencies> key. Driver can provide its own implementation.

=head2 list_pairs

Usage:

 $xchg->list_pairs => [$status, $reason, $payload, \%resmeta]

List all pairs available for trading.

Method must return enveloped result. Payload must be an array containing pair
names (except when C<detail> argument is set to true, in which case method must
return array of records/hashrefs).

Pair names must be in the form of I<< <currency1>/<currency2> >> where I<<
<currency2> >> is the base currency code. Currency codes must follow list in
L<CryptoCurrency::Catalog>. Some example pair names: BTC/USD, ETH/BTC.

Known options:

=over

=item * native

Boolean. Default 0. If set to 1, method must return pair codes in native
exchange form instead of canonical/standardized form.

=item * detail

Boolean. Default 0. If set to 1, method must return array of records/hashrefs
instead of just array of strings (pair names).

Record must contain these keys: C<name> (pair name, str). Record can contain
additional keys.

=back

=head2 get_order_book

Usage:

 $xchg->get_order_book => [$status, $reason, $payload, \%resmeta]

Method should return payload as an array of hashrefs. Each hashref (record)
should contain these keys: C<type> (str, either "buy" or "sell"), C<price>
(float), C<amount> (float). Buy (bid, purchase) records must be sorted from
highest price to lowest price. Sell (ask, offer) records must be sorted from
lowest price to highest.

Known options:

=over

=item * pair

String. Pair.

=item * type

String. Can be set to "buy" or "sell" to filter only return buy records or sell
records respectively.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-exchange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-exchange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cryp-exchange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
