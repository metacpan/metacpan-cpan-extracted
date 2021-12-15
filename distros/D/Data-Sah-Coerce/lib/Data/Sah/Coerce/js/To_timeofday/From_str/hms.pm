package Data::Sah::Coerce::js::To_timeofday::From_str::hms;

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
        summary => 'Coerce timeofday from string of the form hh:mm:ss',
        might_fail => 1, # we throw exception h:m:s is invalid
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='string'",
        "($dt).match(/^([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2}(?:\\.[0-9]{1,9})?))?\$/)",
    );

    # note: (function(a,b,c){...})() is a trick to simulate lexical variables
    $res->{expr_coerce} = join(
        "",
        "(function (_m) { ",
        "  _m = ($dt).match(/^([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2}(?:\\.[0-9]{1,9})?))?\$/); ", # assume always match, because of expr_match
        "  _m[1] = parseInt(_m[1]);   if (_m[1] >= 24) { return ['Invalid hour '+_m[1]+', must be between 0-23'] } ",
        "  _m[2] = parseInt(_m[2]);   if (_m[2] >= 60) { return ['Invalid minute '+_m[2]+', must be between 0-59'] } ",
        "  _m[3] = _m[3] ? parseFloat(_m[3]) : 0; if (_m[3] >= 60) { return ['Invalid second '+_m[3]+', must be between 0-60'] } ",
        "  return [null, _m[1]*3600 + _m[2]*60 + _m[3]] ",
        "})()",
    );
    $res;
}

1;
# ABSTRACT: Coerce timeofday from string of the form hh:mm:ss

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::To_timeofday::From_str::hms - Coerce timeofday from string of the form hh:mm:ss

=head1 VERSION

This document describes version 0.052 of Data::Sah::Coerce::js::To_timeofday::From_str::hms (from Perl distribution Data-Sah-Coerce), released on 2021-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["timeofday",{"x.perl.coerce_rules"=>["From_str::hms"]}]

=head1 DESCRIPTION

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
