package Data::Sah::Coerce::js::duration::float_secs;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.023'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 2,
        enable_by_default => 1,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "(typeof($dt)=='number' || typeof($dt)=='string' && $dt.match(/^[0-9]+(?:\\.[0-9]+)?\$/))",
        "parseFloat($dt) >= 0", # we don't allow negative duration
        "!isNaN(parseFloat($dt))",
        "isFinite(parseFloat($dt))", # we don't allow infinite duration
    );

    $res->{expr_coerce} = "parseFloat($dt)";

    $res;
}

1;
# ABSTRACT: Coerce duration from number (assumed to be number of seconds)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::duration::float_secs - Coerce duration from number (assumed to be number of seconds)

=head1 VERSION

This document describes version 0.023 of Data::Sah::Coerce::js::duration::float_secs (from Perl distribution Data-Sah-Coerce), released on 2017-07-10.

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

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
