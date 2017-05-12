package Bencher::Formatter;

our $DATE = '2017-02-20'; # DATE
our $VERSION = '1.036'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

1;
# ABSTRACT: Base class for formatter

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter - Base class for formatter

=head1 VERSION

This document describes version 1.036 of Bencher::Formatter (from Perl distribution Bencher-Backend), released on 2017-02-20.

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
