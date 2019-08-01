package Data::Sah::Coerce::perl::str::str_to_cryptoexchange_currency_pair;

our $DATE = '2019-07-26'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        might_fail => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"CryptoCurrency::Catalog"} //= 0;
    $res->{modules}{"Locale::Codes::Currency_Codes"} //= 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$res; ",
        "  my (\$cur1, \$cur2) = $dt =~ m!\\A(\\S+)/(\\S+)\\z! or do { \$res = ['Invalid currency pair syntax, please use CUR1/CUR2 syntax']; goto RETURN_RES }; ",

        # check currency1
        "  my \$cat = CryptoCurrency::Catalog->new; ",
        "  my \$rec; eval { \$rec = \$cat->by_code(\$cur1) }; ",
        "  if (\$@) { \$res = ['Unknown cryptocurrency code: ' . \$cur1]; goto RETURN_RES } ",
        "  \$cur1 = \$rec->{code}; ",

        # check currency2
        "  \$cur2 = uc \$cur2; ",
        "  if (\$Locale::Codes::Data{currency}{code2id}{alpha}{\$cur2}) { } else { ",
        "    my \$rec; eval { \$rec = \$cat->by_code(\$cur2) }; ",
        "    if (\$@) { \$res = ['Unknown fiat/cryptocurrency code: ' . \$cur2]; goto RETURN_RES } ",
        "  } ",

        # check currency1 differs from currency2
        "  if (\$cur1 eq \$cur2) { \$res = ['Currency and base currency must differ']; goto RETURN_RES } ",

        "  \$res = [undef, \"\$cur1/\$cur2\"]; ",

        "  RETURN_RES: \$res; ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce string into cryptoexchange currency pair, e.g. LTC/USD

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::str::str_to_cryptoexchange_currency_pair - Coerce string into cryptoexchange currency pair, e.g. LTC/USD

=head1 VERSION

This document describes version 0.003 of Data::Sah::Coerce::perl::str::str_to_cryptoexchange_currency_pair (from Perl distribution Data-Sah-Coerce-perl-str-str_to_cryptoexchange_currency_pair), released on 2019-07-26.

=head1 DESCRIPTION

This coercion rules checks that:

=over

=item * string is in the form of "I<currency1>/I<currency2>"

=item * I<currency1> is a known cryptocurrency code

=item * I<currency2> is a known fiat currency or cryptocurrency code

=item * I<currency1> is not the same as I<currency2>

=back

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["str", "x.perl.coerce_rules"=>["str_to_cryptoexchange_currency_pair"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-str-str_to_cryptoexchange_currency_pair>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-str-str_to_cryptoexchange_currency_pair>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-str-str_to_cryptoexchange_currency_pair>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
