package Data::Sah::Coerce::js::timeofday::str_hms;

our $DATE = '2018-12-16'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 1,
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
        "($dt).match(/^([0-9]{2}):([0-9]{2}):([0-9]{2}(?:\\.[0-9]{1,9})?)\$/)",
    );

    # note: (function(a,b,c){...})() is a trick to simulate lexical variables
    $res->{expr_coerce} = join(
        "",
        "(function (_m) { ",
        "  _m = ($dt).match(/^([0-9]{2}):([0-9]{2}):([0-9]{2}(?:\\.[0-9]{1,9})?)\$/); ", # assume always match, because of expr_match
        "  _m[1] = parseInt(_m[1]);   if (_m[1] >= 24) { return ['Invalid hour '+_m[1]+', must be between 0-23'] } ",
        "  _m[2] = parseInt(_m[2]);   if (_m[2] >= 60) { return ['Invalid minute '+_m[2]+', must be between 0-59'] } ",
        "  _m[3] = parseFloat(_m[3]); if (_m[3] >= 60) { return ['Invalid second '+_m[3]+', must be between 0-60'] } ",
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

Data::Sah::Coerce::js::timeofday::str_hms - Coerce timeofday from string of the form hh:mm:ss

=head1 VERSION

This document describes version 0.030 of Data::Sah::Coerce::js::timeofday::str_hms (from Perl distribution Data-Sah-Coerce), released on 2018-12-16.

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

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
