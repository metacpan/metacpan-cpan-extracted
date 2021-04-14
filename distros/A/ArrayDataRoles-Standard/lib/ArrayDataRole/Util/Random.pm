package ArrayDataRole::Util::Random;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-13'; # DATE
our $DIST = 'ArrayDataRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

# enabled by Role::Tiny
#use strict;
#use warnings;

use Role::Tiny;

requires 'reset_iterator';
requires 'get_elem';

sub get_rand_elems {
    my ($self, $num_elems) = @_;
    my @elems;
    my $i = -1;
    $self->reset_iterator;
    while (defined(my $elem = $self->get_elem)) {
        $i++;
        if (@elems < $num_elems) {
            # we haven't reached $num_elems, insert elem to array in a random
            # position
            splice @elems, rand(@elems+1), 0, $elem;
        } else {
            # we have reached $num_elems, just replace an elem randomly, using
            # algorithm from Learning Perl, slightly modified
            rand($i+1) < @elems and splice @elems, rand(@elems), 1, $elem;
        }
    }
    \@elems;
}

sub get_rand_elem {
    my $self = shift;
    my $rows = $self->get_rand_elems(1);
    $rows ? $rows->[0] : undef;
}

1;
# ABSTRACT: Provide utility methods related to getting random elment(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Util::Random - Provide utility methods related to getting random elment(s)

=head1 VERSION

This document describes version 0.001 of ArrayDataRole::Util::Random (from Perl distribution ArrayDataRoles-Standard), released on 2021-04-13.

=head1 DESCRIPTION

This role provides some utility methods related to getting random element(s)
from the array. Note that the methods perform a full, one-time, scan of the
array using C<get_elem>. For huge array, this might not be a good idea. Seekable
array can use the more efficient L<ArrayDataRole::Util::Random::Seekable>.

=head1 PROVIDED METHODS

=head2 get_rand_elem

Usage:

 my $elem = $ary->get_rand_elem; # might return undef

Get a single random element from the array. If array is empty, will return
undef.

=head2 get_rand_elems

Usage:

 my $elems = $ary->get_rand_elems($n);

Get C<$n> random elements from the array. No duplicate elements (doesn't mean
there won't be any duplicates, if the array originally contains duplicates). If
array contains less than C<$n> elements, only that many elements will be
returned.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayDataRoles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ArrayDataRole::Util::Random::Seekable>

Other C<ArrayDataRole::Util::*>

L<ArrayData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
