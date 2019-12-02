package Data::Sah::Coerce::perl::To_str::From_str::ToCryptoCurrencyCode;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_str-From_str-ToCryptoCurrencyCode'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce string containing cryptocurrency code/name/safename to code',
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
    $res->{expr_coerce} = join(
        "",
        "do { my \$cat = CryptoCurrency::Catalog->new; ",
        "my \$rec; eval { \$rec = \$cat->by_code($dt) }; if (\$@) { eval { \$rec = \$cat->by_name($dt) } } if (\$@) { eval { \$rec = \$cat->by_safename($dt) } } ",
        "if (\$@) { ['Unknown cryptocurrency code/name/safename: ' . $dt] } else { [undef, \$rec->{code}] } ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce string containing cryptocurrency code/name/safename to code

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_str::ToCryptoCurrencyCode - Coerce string containing cryptocurrency code/name/safename to code

=head1 VERSION

This document describes version 0.006 of Data::Sah::Coerce::perl::To_str::From_str::ToCryptoCurrencyCode (from Perl distribution Data-Sah-Coerce-perl-To_str-From_str-ToCryptoCurrencyCode), released on 2019-11-28.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_str-From_str-ToCryptoCurrencyCode>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_str-From_str-ToCryptoCurrencyCode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_str-From_str-ToCryptoCurrencyCode>

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
