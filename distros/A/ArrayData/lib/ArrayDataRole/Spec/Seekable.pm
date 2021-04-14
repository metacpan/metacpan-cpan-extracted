package ArrayDataRole::Spec::Seekable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-11'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.1.0'; # VERSION

use Role::Tiny;

requires 'set_iterator_index';

sub elem_at_index {
    my ($ary, $index) = @_;
    $ary->set_iterator_index($index);
    $ary->elem;
}

sub get_elem_at_index {
    my ($ary, $index) = @_;
    $ary->set_iterator_index($index);
    $ary->get_elem;
}

1;
# ABSTRACT: Required methods for seekable ArrayData::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Spec::Seekable - Required methods for seekable ArrayData::* modules

=head1 VERSION

This document describes version 0.1.0 of ArrayDataRole::Spec::Seekable (from Perl distribution ArrayData), released on 2021-04-11.

=head1 REQUIRED METHODS

=head2 set_iterator_index

Usage:

 $ary->set_iterator_index($index);

C<$index> is a zero-based integer, where 0 refers to the first element, 1 the
second, and so on. Negative index must also be supported, where -1 means the
last element, -2 the second last, and so on.

Must die when seeking outside the range of data (e.g. there are only 5 elements
and this method is called with argument 5 or 6 or -6).

=head1 PROVIDED METHODS

=head2 elem_at_index

Usage:

 my $elem = $ary->elem_at_index($index); # might die

Basically shortcut for:

 $ary->set_row_iterator_index($index);
 $ary->elem;

=head2 get_elem_at_index

Usage:

 my $elem = $ary->get_elem_at_index($index); # might die, might return undef

Basically shortcut for:

 $ary->set_iterator_index($index);
 $ary->get_elem;

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ArrayDataRole::Spec::Basic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
