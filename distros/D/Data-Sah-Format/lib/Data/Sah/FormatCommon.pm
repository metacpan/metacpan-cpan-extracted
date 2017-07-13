package Data::Sah::FormatCommon;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';

my %common_args = (
    format => {
        schema => ['str*', match=>qr/\A\w+(::\w+)*\z/],
        req => 1,
        pos => 0,
    },
    formatter_args => {
        schema => 'hash*',
    },
);

my %gen_formatter_args = (
    %common_args,
    source => {
        summary => 'If set to true, will return formatter source code string'.
            ' instead of compiled code',
        schema => 'bool',
    },
);

1;
# ABSTRACT: Common stuffs for Data::Sah::Format and Data::Sah::FormatJS

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::FormatCommon - Common stuffs for Data::Sah::Format and Data::Sah::FormatJS

=head1 VERSION

This document describes version 0.003 of Data::Sah::FormatCommon (from Perl distribution Data-Sah-Format), released on 2017-07-10.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Format>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
