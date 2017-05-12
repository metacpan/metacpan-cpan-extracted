package Data::Sah::Format::perl::sci2dec;

our $DATE = '2016-06-17'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub format {
    my %args = @_;

    my $dt    = $args{data_term};

    my $res = {};

    $res->{expr} = join(
        "",
        "!defined($dt) ? $dt : ",
        "$dt =~ /\\A(?:[+-]?)(?:\\d+\\.|\\d*\\.(\\d+))[eE]([+-]?\\d+)\\z/ ? do { my \$n = length(\$1 || '') - \$2; \$n=0 if \$n<0; sprintf \"%.\${n}f\", $dt } : ",
        $dt,
    );

    $res;
}

1;
# ABSTRACT: Format scientific notation number as decimal number

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Format::perl::sci2dec - Format scientific notation number as decimal number

=head1 VERSION

This document describes version 0.001 of Data::Sah::Format::perl::sci2dec (from Perl distribution Data-Sah-Format-perl-sci2dec), released on 2016-06-17.

=head1 DESCRIPTION

=for Pod::Coverage ^(format)$

=head1 FORMATTER ARGUMENTS

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Format-perl-sci2dec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Format-perl-sci2dec>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Format-perl-sci2dec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
