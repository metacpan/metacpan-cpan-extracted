package Data::Sah::Coerce::perl::To_array::From_str::csv_row;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-08'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_array-From_str-csv_row'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce a single CSV row to array of scalars',
        prio => 50,
    };
}

our $csv;
sub coerce {
    $csv //= do {
        require Text::CSV;
        Text::CSV->new ({ binary => 1, auto_diag => 1 });
    };

    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = "!ref($dt)";
    $res->{expr_coerce} = join(
        "",
        'do { ',
        '$' . __PACKAGE__ . "::csv->parse($dt); ",
        '[$' . __PACKAGE__ . "::csv->fields]; ",
        ' }',
    );

    $res;
}

1;
# ABSTRACT: Coerce a single CSV row to array of scalars

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_array::From_str::csv_row - Coerce a single CSV row to array of scalars

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::To_array::From_str::csv_row (from Perl distribution Data-Sah-Coerce-perl-To_array-From_str-csv_row), released on 2021-04-08.

=head1 SYNOPSIS

To use in a Sah schema:

 ["array",{"x.perl.coerce_rules"=>["From_str::csv_row"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_array-From_str-csv_row>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_array-From_str-csv_row>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_array-From_str-csv_row/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_array::From_str::comma_sep> accomplishes roughly
the same thing without handling escapes or quotes.

L<Data::Sah::Coerce::perl::To_array::From_str::tsv_row>

L<Data::Sah::Coerce::perl::To_array::From_str::csv>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
