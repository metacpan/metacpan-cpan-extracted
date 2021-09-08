package Data::Sah::Coerce::js::To_array::From_str::comma_sep;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-08'; # DATE
our $DIST = 'Data-Sah-CoerceBundle-To_array-From_str-comma_sep'; # DIST
our $VERSION = '0.013'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce array from a comma-separated items in a string',
        prio => 60, # a bit lower than normal
        args => {
            separator => {
                schema => ['str*', min_len=>1],
                default => ',',
            },
        },
    };
}

sub coerce {
    require String::JS;

    my %cargs = @_;

    my $dt = $cargs{data_term};
    my $gen_args = $cargs{args};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='string'",
    );

    my $sep = $gen_args->{separator} // ',';
    $res->{expr_coerce} = "$dt.split(RegExp('\\\\s*' + String(" . String::JS::encode_js_string($sep) . ").replace(/(\\W)/g, '\\\\\$1') + '\\\\s*'))";

    $res;
}

1;
# ABSTRACT: Coerce array from a comma-separated items in a string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::To_array::From_str::comma_sep - Coerce array from a comma-separated items in a string

=head1 VERSION

This document describes version 0.013 of Data::Sah::Coerce::js::To_array::From_str::comma_sep (from Perl distribution Data-Sah-CoerceBundle-To_array-From_str-comma_sep), released on 2021-04-08.

=head1 SYNOPSIS

To use in a Sah schema:

 ["array",{"x.perl.coerce_rules"=>["From_str::comma_sep"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-CoerceBundle-To_array-From_str-comma_sep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-CoerceBundle-To_array-From_str-comma_sep>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Data-Sah-CoerceBundle-To_array-From_str-comma_sep/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
