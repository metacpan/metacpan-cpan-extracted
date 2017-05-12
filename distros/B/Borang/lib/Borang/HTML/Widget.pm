package Borang::HTML::Widget;

our $DATE = '2015-09-22'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010;
use strict;
use warnings;

use Mo qw(build default);

#has form => (is => 'rw');
has name => (is => 'rw');
has value => (is => 'rw');

1;
# ABSTRACT: Base class for HTML form widgets

__END__

=pod

=encoding UTF-8

=head1 NAME

Borang::HTML::Widget - Base class for HTML form widgets

=head1 VERSION

This document describes version 0.02 of Borang::HTML::Widget (from Perl distribution Borang), released on 2015-09-22.

=head1 ATTRIBUTES

=head2 name => str

Widget name.

=head2 value => any

The value that the widget stores.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Borang>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Borang>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Borang>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
