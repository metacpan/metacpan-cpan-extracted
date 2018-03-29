package Data::Sah::Coerce::js::bool::str;

our $DATE = '2018-03-27'; # DATE
our $VERSION = '0.024'; # VERSION

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

    my $res = {};

    my $re      = '/^(yes|no|true|false|on|off|1|0)$/i';
    my $re_true = '/^(yes|true|on|1)$/i';

    $res->{expr_match} = join(
        " && ",
        "typeof($dt)=='string'",
        "$dt.match($re)",
    );

    # XXX how to avoid matching twice? even three times now

    $res->{expr_coerce} = "(function(_m) { _m = $dt.match($re); return _m[1].match($re_true) ? true : false })()";

    $res;
}

1;
# ABSTRACT: Coerce "true","yes",etc to true and "false","no",etc to false

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::bool::str - Coerce "true","yes",etc to true and "false","no",etc to false

=head1 VERSION

This document describes version 0.024 of Data::Sah::Coerce::js::bool::str (from Perl distribution Data-Sah-Coerce), released on 2018-03-27.

=head1 DESCRIPTION

Convert some strings like "true", "yes", "on", "1" (matched case-insensitively)
to boolean true.

Convert "false", "no", "off", "0" (matched case-insensitively) to boolean false.

All other strings are not coerced to boolean.

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
