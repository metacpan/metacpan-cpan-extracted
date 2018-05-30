package Data::Sah::Coerce::perl::str::str_to_cryptocurrency_safename;

our $DATE = '2018-05-29'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 0,
        might_die => 1,
        prio => 50,
        precludes => [qr/\Astr_to_cryptocurrency_(.+)?\z/],
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
        "if (\$@) { die 'Unknown cryptocurrency code/name/safename: ' . $dt } ",
        "\$rec->{safename} }",
    );

    $res;
}

1;
# ABSTRACT: Coerce string containing cryptocurrency code/name/safename to safename

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::str::str_to_cryptocurrency_safename - Coerce string containing cryptocurrency code/name/safename to safename

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::str::str_to_cryptocurrency_safename (from Perl distribution Data-Sah-Coerce-perl-str-str_to_cryptocurrency_safename), released on 2018-05-29.

=head1 DESCRIPTION

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["str", "x.perl.coerce_rules"=>["str_to_cryptocurrency_safename"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-str-str_to_cryptocurrency_safename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-str-str_to_cryptocurrency_safename>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-str-str_to_cryptocurrency_safename>

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
