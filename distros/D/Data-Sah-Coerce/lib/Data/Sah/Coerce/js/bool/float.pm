package Data::Sah::Coerce::js::bool::float;

our $DATE = '2019-01-21'; # DATE
our $VERSION = '0.032'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='number'",
        "$dt == 0 || $dt == 1",
    );

    # XXX how to avoid matching twice? even three times now

    $res->{expr_coerce} = "$dt == 1 ? true : false";

    $res;
}

1;
# ABSTRACT: Coerce 0 to false and 1 to true

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::bool::float - Coerce 0 to false and 1 to true

=head1 VERSION

This document describes version 0.032 of Data::Sah::Coerce::js::bool::float (from Perl distribution Data-Sah-Coerce), released on 2019-01-21.

=head1 DESCRIPTION

Convert number 1 to false and 0 to true. Any other number is not coerced to
boolean.

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

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
