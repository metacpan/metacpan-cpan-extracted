package Data::Sah::Coerce::js::To_duration::From_str::iso8601;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.052'; # VERSION

sub meta {
    +{
        v => 4,
        summary => 'Coerce duration from (subset of) ISO8601 string (e.g. "P1Y2M", "P14M")',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to};

    my $res = {};

    my $re_num = '[0-9]+(?:\\.[0-9]+)?';
    # js doesn't support /x flag, nor \A and \z. oh my
    #                                     #1=Y           #2=M(on)       #3=W           #4=D               #5=H           #6=M(in)       #7=S
    my $expr_re_match = "$dt.match(/^P(?:($re_num)Y)?(?:($re_num)M)?(?:($re_num)W)?(?:($re_num)D)?(?:T(?:($re_num)H)?(?:($re_num)M)?(?:($re_num)S)?)?\$/)";
    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='string'",
        $expr_re_match,
    );

    # XXX i need a trick to avoid doing regex match twice

    # approximation
    $res->{expr_coerce} = "(function(_m) { _m = $expr_re_match; return ((_m[1]||0)*365.25*86400 + (_m[2]||0)*30.4375*86400 + (_m[3]||0)*7*86400 + (_m[4]||0)*86400 + (_m[5]||0)*3600 + (_m[6]||0)*60 + (_m[7]||0)*1) })()";

    $res;
}

1;
# ABSTRACT: Coerce duration from (subset of) ISO8601 string (e.g. "P1Y2M", "P14M")

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::To_duration::From_str::iso8601 - Coerce duration from (subset of) ISO8601 string (e.g. "P1Y2M", "P14M")

=head1 VERSION

This document describes version 0.052 of Data::Sah::Coerce::js::To_duration::From_str::iso8601 (from Perl distribution Data-Sah-Coerce), released on 2021-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["duration",{"x.perl.coerce_rules"=>["From_str::iso8601"]}]

=head1 DESCRIPTION

The format is:

 PnYnMnWnDTnHnMnS

Examples: "P1Y2M" (equals to "P14M", 14 months), "P1DT13M" (1 day, 13 minutes).

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
