
package Array::Iterator::BiDirectional;

use strict;
use warnings;

use Array::Iterator;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-21'; # DATE
our $DIST = 'Array-Iterator'; # DIST
our $VERSION = '0.132'; # VERSION

our @ISA = qw(Array::Iterator);

sub has_previous {
	my ($self, $n) = @_;

    if(not defined $n) { $n = 1 }
    elsif(not $n)      { die "has_previous(0) doesn't make sense, did you mean current()?" }
    elsif($n < 0)      { die "has_previous() with negative argument doesn't make sense, did you mean has_next()?" }

    my $idx = $self->_current_index - $n;

	return ($idx > 0) ? 1 : 0;
}

sub hasPrevious { my $self = shift; $self->has_previous(@_) }

sub previous {
	my ($self) = @_;
    (($self->_current_index - 1) > 0)
        || die "Out Of Bounds : no more elements";
        $self->_iterated = 1;
	return $self->_getItem($self->_iteratee, --$self->_current_index);
}

sub get_previous {
    my ($self) = @_;
    return undef unless (($self->_current_index - 1) > 0); ## no critic: Subroutines::ProhibitExplicitReturnUndef
    $self->_iterated = 1;
    return $self->_getItem($self->_iteratee, --$self->_current_index);
}

sub getPrevious { my $self = shift; $self->get_previous(@_) }

sub look_back {
    my ($self, $n) = @_;

    if(not defined $n) { $n = 1 }
    elsif(not $n)      { die "look_back(0) doesn't make sense, did you mean get_previous()?" }
    elsif($n < 0)      { die "look_back() with negative argument doesn't make sense, did you mean get_next()?" }

    my $idx = $self->_current_index - ($n + 1);

    return undef unless ($idx > 0); ## no critic: Subroutines::ProhibitExplicitReturnUndef
    $self->_iterated = 1;
    return $self->_getItem($self->_iteratee, $idx);
}

sub lookBack { my $self = shift; $self->look_back(@_) }

1;
# ABSTRACT: A subclass of Array::Iterator to allow forwards and backwards iteration

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Iterator::BiDirectional - A subclass of Array::Iterator to allow forwards and backwards iteration

=head1 VERSION

This document describes version 0.132 of Array::Iterator::BiDirectional (from Perl distribution Array-Iterator), released on 2023-11-21.

=head1 SYNOPSIS

  use Array::Iterator::BiDirectional;

  # create an instance of the iterator
  my $i = Array::Iterator::BiDirectional->new(1 .. 100);

  while ($some_condition_exists) {
      # get the latest item from
      # the iterator
      my $current = $i->get_next();
      # ...
      if ($something_happens) {
          # back up the iterator
          $current = $i->get_previous();
      }
  }

=head1 DESCRIPTION

Occasionally it is useful for an iterator to go in both directions, forward and backward. One example would be token processing. When looping though tokens it is sometimes necessary to advance forward looking for a match to a rule. If the match fails, a bi-directional iterator can be moved back so that the next rule can be tried.

=for Pod::Coverage .+

=head1 METHODS

This is a subclass of Array::Iterator, only those methods that have been added are documented here, refer to the Array::Iterator documentation for more information.

=over 4

=item B<has_previous([$n])>

This method works much like C<hasNext> does, it will return true (C<1>) unless the beginning of the array has been reached, and false (C<0>) otherwise.

Optional argument has the same meaning except that it specifies C<$n>th previous element.

=item B<previous>

This method is much like C<next>. It will return the previous item in the iterator, and throw an exception if it attempts to reach past the beginning of the array.

=item B<get_previous>

This method is much like C<get_next>. It will return the previous item in the iterator, and return undef if it attempts to reach past the beginning of the array.

=item B<look_back([$n])>

This is the counterpart to C<peek>, it will return the previous items in the iterator, but will not affect the internal counter.

Optional argument has the same meaning except that it specifies C<$n>th previous element.

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
