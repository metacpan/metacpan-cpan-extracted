package Data::Sah::Coerce::perl::bool::str;

our $DATE = '2018-12-16'; # DATE
our $VERSION = '0.031'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 3,
        enable_by_default => 0,
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "1",
    );

    $res->{expr_coerce} = "$dt =~ /\\A(yes|true|on)\\z/i ? 1 : $dt =~ /\\A(no|false|off|0)\\z/i ? '' : $dt";

    $res;
}

1;
# ABSTRACT: Convert "yes","true",etc to "1", and "no","false",etc to ""

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::bool::str - Convert "yes","true",etc to "1", and "no","false",etc to ""

=head1 VERSION

This document describes version 0.031 of Data::Sah::Coerce::perl::bool::str (from Perl distribution Data-Sah-Coerce), released on 2018-12-16.

=head1 DESCRIPTION

This is an optional rule (not enabled by default) that converts "true", "yes",
"on" (matched case-insensitively) to "1" and "false", "no", "off", "0" (matched
case-insensitively) to "". All other strings are left untouched.

This rule is not enabled because it is incompatible with Perl's notion of
true/false. Perl regards all non-empty string that isn't "0" (including "no",
"false", "off") as true.

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
