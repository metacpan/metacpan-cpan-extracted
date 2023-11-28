
package Array::Iterator::Reusable;

use strict;
use warnings;

use Array::Iterator;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-21'; # DATE
our $DIST = 'Array-Iterator'; # DIST
our $VERSION = '0.132'; # VERSION

our @ISA = qw(Array::Iterator);

sub reset {
    my ($self) = @_;
    $self->_iterated = 0;
    $self->_current_index = 0;
}

1;
# ABSTRACT: A subclass of Array::Iterator to allow reuse of iterators

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Iterator::Reusable - A subclass of Array::Iterator to allow reuse of iterators

=head1 VERSION

This document describes version 0.132 of Array::Iterator::Reusable (from Perl distribution Array-Iterator), released on 2023-11-21.

=head1 SYNOPSIS

  use Array::Iterator::Reusable;

  # create an iterator with an array
  my $i = Array::Iterator::Reusable->new(1 .. 100);

  # do something with the iterator
  my @accumulation;
  push @accumulation => { item => $iterator->next() } while $iterator->has_next();

  # now reset the iterator so we can do it again
  $iterator->reset();

=head1 DESCRIPTION

Sometimes you don't want to have to throw out your iterator each time you have exhausted it. This class adds the C<reset> method to allow reuse of an iterator. This is a very simple addition to the Array::Iterator class of a single method.

=for Pod::Coverage .+

=head1 METHODS

This is a subclass of Array::Iterator, only those methods that have been added are documented here, refer to the Array::Iterator documentation for more information.

=over 4

=item B<reset>

This resets the internal counter of the iterator back to the start of the array.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Iterator>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Iterator>.

=head1 SEE ALSO

This is a subclass of B<Array::Iterator>, please refer to it for more documentation.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 ORIGINAL AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2017, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 ORIGINAL COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Iterator>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
