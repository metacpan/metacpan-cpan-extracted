package Data::Sah::Coerce::perl::To_str::From_str::ToFiatOrCryptoCurrencyCode;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_str-From_str-ToFiatOrCryptoCurrencyCode'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce string containing fiat/cryptocurrency code/name/safename to uppercase code',
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
        "  my \$uc = uc($dt); ",
        "  if (\$Locale::Codes::Data{currency}{code2id}{alpha}{\$uc}) { \$res = [undef, \$uc]; goto RETURN_RES } ",
        "  my \$cat = CryptoCurrency::Catalog->new; ",
        "  my \$rec; eval { \$rec = \$cat->by_code($dt) }; if (\$@) { eval { \$rec = \$cat->by_name($dt) } } if (\$@) { eval { \$rec = \$cat->by_safename($dt) } } ",
        "  if (\$@) { \$res = ['Unknown fiat/cryptocurrency code/name/safename: ' . $dt] } else { \$res = [undef, \$rec->{code}] } ",
        "  RETURN_RES: \$res; ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce string containing fiat/cryptocurrency code/name/safename to uppercase code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_str::ToFiatOrCryptoCurrencyCode - Coerce string containing fiat/cryptocurrency code/name/safename to uppercase code

=head1 VERSION

This document describes version 0.004 of Data::Sah::Coerce::perl::To_str::From_str::ToFiatOrCryptoCurrencyCode (from Perl distribution Data-Sah-Coerce-perl-To_str-From_str-ToFiatOrCryptoCurrencyCode), released on 2019-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["str",{"x.perl.coerce_rules"=>["From_str::ToFiatOrCryptoCurrencyCode"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_str-From_str-ToFiatOrCryptoCurrencyCode>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_str-From_str_ToFiatOrCryptoCurrencyCode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_str-From_str-ToFiatOrCryptoCurrencyCode>

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
