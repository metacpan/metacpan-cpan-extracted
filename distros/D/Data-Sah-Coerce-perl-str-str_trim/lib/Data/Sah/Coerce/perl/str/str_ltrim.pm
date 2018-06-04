package Data::Sah::Coerce::perl::str::str_ltrim;

our $DATE = '2018-06-04'; # DATE
our $VERSION = '0.002'; # VERSION

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

    $res->{expr_match} = "!ref($dt)";
    $res->{expr_coerce} = join(
        "",
        "do { my \$res = $dt; \$res =~ s/\\A\\s+//s; \$res }",
    );

    $res;
}

1;
# ABSTRACT: Trim whitespaces at the beginning of string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::str::str_ltrim - Trim whitespaces at the beginning of string

=head1 VERSION

This document describes version 0.002 of Data::Sah::Coerce::perl::str::str_ltrim (from Perl distribution Data-Sah-Coerce-perl-str-str_trim), released on 2018-06-04.

=head1 DESCRIPTION

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["str", "x.perl.coerce_rules"=>["str_ltrim"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-str-str_trim>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-str-str_trim>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-str-str_trim>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
