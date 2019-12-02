package Data::Sah::Coerce::perl::To_str::From_str::ToCryptoExchangeSafename;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_str-From_str-ToCryptoExchangeSafename'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce string containing cryptoexchange code/name/safename to safename',
        might_fail => 1,
        prio => 50,
        precludes => [qr/\Astr_to_cryptoexchange_(.+)?\z/],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{modules}{"CryptoExchange::Catalog"} //= 0;
    $res->{expr_coerce} = join(
        "",
        "do { my \$cat = CryptoExchange::Catalog->new; my \@data = \$cat->all_data; ",
        "my \$lc = lc($dt); my \$rec; for (\@data) { if (defined(\$_->{code}) && \$lc eq lc(\$_->{code}) || \$lc eq lc(\$_->{name}) || \$lc eq \$_->{safename}) { \$rec = \$_; last } } ",
        "if (!\$rec) { ['Unknown cryptoexchange code/name/safename: ' . \$lc] } else { [undef, \$rec->{safename}] } ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Coerce string containing cryptoexchange code/name/safename to safename

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_str::ToCryptoExchangeSafename - Coerce string containing cryptoexchange code/name/safename to safename

=head1 VERSION

This document describes version 0.006 of Data::Sah::Coerce::perl::To_str::From_str::ToCryptoExchangeSafename (from Perl distribution Data-Sah-Coerce-perl-To_str-From_str-ToCryptoExchangeSafename), released on 2019-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["str",{"x.perl.coerce_rules"=>["From_str::ToCryptoExchangeSafename"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_str-From_str-ToCryptoExchangeSafename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_str-From_str-ToCryptoExchangeSafename>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_str-From_str-ToCryptoExchangeSafename>

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
