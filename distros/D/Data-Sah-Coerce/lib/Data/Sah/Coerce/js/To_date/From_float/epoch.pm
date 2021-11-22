package Data::Sah::Coerce::js::To_date::From_float::epoch;

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from number (assumed to be epoch)',
        prio => 50,
    };
}

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-18'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.051'; # VERSION

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='number'",
        "$dt >= " . (10**8),
        "$dt <= " . (2**31),
    );

    $res->{expr_coerce} = "(new Date($dt * 1000))";

    $res;
}

1;
# ABSTRACT: Coerce date from number (assumed to be epoch)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::To_date::From_float::epoch - Coerce date from number (assumed to be epoch)

=head1 VERSION

This document describes version 0.051 of Data::Sah::Coerce::js::To_date::From_float::epoch (from Perl distribution Data-Sah-Coerce), released on 2021-10-18.

=head1 SYNOPSIS

To use in a Sah schema:

 ["date",{"x.perl.coerce_rules"=>["From_float::epoch"]}]

=head1 DESCRIPTION

To avoid confusion with integer that contains "YYYY", "YYYYMM", or "YYYYMMDD",
we only do this coercion if data is an integer between 10^8 and 2^31.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
