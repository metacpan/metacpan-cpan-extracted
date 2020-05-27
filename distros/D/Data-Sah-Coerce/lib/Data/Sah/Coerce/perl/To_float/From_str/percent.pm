package Data::Sah::Coerce::perl::To_float::From_str::percent;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.049'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce float from percent string (e.g. "100.5%")',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([+-]?\\d+(?:\\.\\d*)?)%\\z/",
    );

    $res->{expr_coerce} = "\$1/100";
    $res;
}

1;
# ABSTRACT: Coerce float from percent string (e.g. "100.5%")

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_float::From_str::percent - Coerce float from percent string (e.g. "100.5%")

=head1 VERSION

This document describes version 0.049 of Data::Sah::Coerce::perl::To_float::From_str::percent (from Perl distribution Data-Sah-Coerce), released on 2020-05-24.

=head1 SYNOPSIS

To use in a Sah schema:

 ["float",{"x.perl.coerce_rules"=>["From_str::percent"]}]

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
