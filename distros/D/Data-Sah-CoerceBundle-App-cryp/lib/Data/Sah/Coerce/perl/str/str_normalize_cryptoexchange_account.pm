package Data::Sah::Coerce::perl::str::str_normalize_cryptoexchange_account;

our $DATE = '2018-05-31'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 0,
        might_die => 1,
        prio => 50,
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
        "do { my (\$xch, \$acc); $dt =~ m!(.+)/(.+)! and (\$xch, \$acc) = (\$1, \$2) or (\$xch, \$acc) = ($dt, 'default'); ",
        "\$acc =~ /\\A[A-Za-z0-9_-]+\\z/ or die 'Invalid account syntax: ' . \$acc . ', please only use letters/numbers/underscores/dashes'; ",
        "my \$cat = CryptoExchange::Catalog->new; my \@data = \$cat->all_data; ",
        "my \$lc = lc(\$xch); my \$rec; for (\@data) { if (defined(\$_->{code}) && \$lc eq lc(\$_->{code}) || \$lc eq lc(\$_->{name}) || \$lc eq \$_->{safename}) { \$rec = \$_; last } } ",
        "unless (\$rec) { die 'Unknown cryptoexchange code/name/safename: ' . \$lc } ",
        "qq(\$rec->{safename}/\$acc) }",
    );

    $res;
}

1;
# ABSTRACT: Normalize cryptoexchange account

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::str::str_normalize_cryptoexchange_account - Normalize cryptoexchange account

=head1 VERSION

This document describes version 0.002 of Data::Sah::Coerce::perl::str::str_normalize_cryptoexchange_account (from Perl distribution Data-Sah-CoerceBundle-App-cryp), released on 2018-05-31.

=head1 DESCRIPTION

Cryptoexchange account is of the following format:

 cryptoexchange/account

where C<cryptoexchange> is the name/code/safename of cryptoexchange as listed in
L<CryptoExchange::Catalog>. This coercion rule normalizes cryptoexchange into
safename and will die if name/code/safename is not listed in the catalog module.

C<account> must also be [A-Za-z0-9_-]+ only.

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["str", "x.perl.coerce_rules"=>["str_normalize_cryptocurrency_account"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-CoerceBundle-App-cryp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-CoerceBundle-App-cryp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-CoerceBundle-App-cryp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
