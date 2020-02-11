package Data::Sah::Coerce::perl::To_str::From_str::to_lower_first;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Data-Sah-Coerce-perl-To_str-From_str-to_upper'; # DIST
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => "(DEPRECATED) Coerce string's first character to lower case",
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
        "lcfirst($dt)",
    );

    $res;
}

1;
# ABSTRACT: (DEPRECATED) Coerce string's first character to lower case

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_str::From_str::to_lower_first - (DEPRECATED) Coerce string's first character to lower case

=head1 VERSION

This document describes version 0.007 of Data::Sah::Coerce::perl::To_str::From_str::to_lower_first (from Perl distribution Data-Sah-Coerce-perl-To_str-From_str-to_upper), released on 2020-02-11.

=head1 SYNOPSIS

To use in a Sah schema:

 ["str",{"x.perl.coerce_rules"=>["From_str::to_lower_first"]}]

=head1 DESCRIPTION

DEPRECATION NOTICE: filter is now more appropriate as multiple filters can be
applied to data.

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce-perl-To_str-From_str-to_upper>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce-perl-To_str-From_str-to_upper>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce-perl-To_str-From_str-to_upper>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
