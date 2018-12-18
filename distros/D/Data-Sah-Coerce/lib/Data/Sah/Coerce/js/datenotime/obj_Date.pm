package Data::Sah::Coerce::js::datenotime::obj_Date;

our $DATE = '2018-12-16'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::js::date::obj_Date';

1;
# ABSTRACT: Coerce datenotime from Date object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::js::datenotime::obj_Date - Coerce datenotime from Date object

=head1 VERSION

This document describes version 0.030 of Data::Sah::Coerce::js::datenotime::obj_Date (from Perl distribution Data-Sah-Coerce), released on 2018-12-16.

=head1 DESCRIPTION

This is basically just to throw an error when date is invalid.

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
