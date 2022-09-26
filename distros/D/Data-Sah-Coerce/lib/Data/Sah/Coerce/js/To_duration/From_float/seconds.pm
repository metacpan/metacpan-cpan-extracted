package Data::Sah::Coerce::js::To_duration::From_float::seconds;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-22'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.053'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce duration from number (assumed to be number of seconds)',
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

Data::Sah::Coerce::js::To_duration::From_float::seconds - Coerce duration from number (assumed to be number of seconds)

=head1 VERSION

This document describes version 0.053 of Data::Sah::Coerce::js::To_duration::From_float::seconds (from Perl distribution Data-Sah-Coerce), released on 2022-09-22.

=head1 SYNOPSIS

To use in a Sah schema:

 ["duration",{"x.perl.coerce_rules"=>["From_float::seconds"]}]

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
