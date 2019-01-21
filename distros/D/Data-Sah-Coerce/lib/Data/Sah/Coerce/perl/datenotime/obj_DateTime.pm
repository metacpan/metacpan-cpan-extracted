package Data::Sah::Coerce::perl::datenotime::obj_DateTime;

our $DATE = '2019-01-21'; # DATE
our $VERSION = '0.032'; # VERSION

use 5.010001;
use strict;
use warnings;

use subroutines 'Data::Sah::Coerce::perl::date::obj_DateTime';

# XXX truncate DateTime to day

1;
# ABSTRACT: Coerce datenotime from DateTime object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::datenotime::obj_DateTime - Coerce datenotime from DateTime object

=head1 VERSION

This document describes version 0.032 of Data::Sah::Coerce::perl::datenotime::obj_DateTime (from Perl distribution Data-Sah-Coerce), released on 2019-01-21.

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

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
