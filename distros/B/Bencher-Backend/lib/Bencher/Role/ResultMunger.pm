package Bencher::Role::ResultMunger;

our $DATE = '2017-02-20'; # DATE
our $VERSION = '1.036'; # VERSION

use 5.010;
use strict;
use warnings;

use Role::Tiny;

requires 'munge_result';

1;
# ABSTRACT: Result munger role

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Role::ResultMunger - Result munger role

=head1 VERSION

This document describes version 1.036 of Bencher::Role::ResultMunger (from Perl distribution Bencher-Backend), released on 2017-02-20.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
