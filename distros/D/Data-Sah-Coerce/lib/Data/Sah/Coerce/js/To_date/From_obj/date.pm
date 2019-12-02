package Data::Sah::Coerce::js::To_date::From_obj::date;

our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.039'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from Date object',
        might_fail => 1, # we return error when date is invalid
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "($dt instanceof Date)",
    );

    $res->{expr_coerce} = "isNaN($dt) ? ['Invalid date'] : [null, $dt]";

    $res;
}

1;
# ABSTRACT: Coerce date from Date object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::To_date::From_obj::date - Coerce date from Date object

=head1 VERSION

This document describes version 0.039 of Data::Sah::Coerce::js::To_date::From_obj::date (from Perl distribution Data-Sah-Coerce), released on 2019-11-28.

=head1 DESCRIPTION

This is basically just to throw an error when date is invalid.

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
