package ArrayDataRole::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-11'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.1.0'; # VERSION

use Role::Tiny;

# constructor
requires 'new';

requires 'elem';
requires 'get_elem';
requires 'get_iterator_index';
requires 'reset_iterator';

# convenience
#provides 'get_all_elems';
#provides 'get_elem_count';

###

sub get_elem_count {
    my $ary = shift;

    $ary->reset_iterator;
    while (1) {
        eval { $ary->elem };
        last if $@;
    }
    $ary->get_iterator_index;
}

sub get_all_elems {
    my $ary = shift;

    my $elems = [];
    $ary->reset_iterator;
    while (1) {
        my $elem;
        eval { $elem = $ary->elem };
        last if $@;
        push @$elems, $elem;
    }
    $elems;
}

sub each_elem {
    my ($ary, $coderef) = @_;

    $ary->reset_iterator;
    my $index = 0;
    while (1) {
        my $elem;
        eval { $elem = $ary->elem };
        last if $@;
        my $res = $coderef->($elem, $ary, $index);
        return 0 unless $res;
        $index++;
    }
    return 1;
}

1;
# ABSTRACT: Required methods for all ArrayData::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Spec::Basic - Required methods for all ArrayData::* modules

=head1 VERSION

This document describes version 0.1.0 of ArrayDataRole::Spec::Basic (from Perl distribution ArrayData), released on 2021-04-11.

=head1 DESCRIPTION

The basic interface is an iterator. You can call L</reset_iterator> to jump to
the first element, then call either L</elem> or L</get_elem> repeatedly to get
elements one at a time until all the elements are retrieved. If you need to go
back to the first element, you can call L</reset_iterator> again.

Some other information methods: L</get_elem_count>, L</get_iterator_index>.

Other convenient methods: L</get_all_elems>.

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $ary = ArrayData::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head2 elem

Usage:

 my $elem = $ary->elem; # might die

Get the next element and move the iterator index one position forward. Must die
if there is no more element to get. See also L</get_elem>.

=head2 get_elem

Usage:

 my $elem = $ary->get_elem; # might return undef which might be ambiguous

Get the next element and move the iterator index one position forward. Must
return C<undef> if there is no more element to get. However, this will be
ambiguous if the array element happens to be C<undef>. It is safe to use if you
know for sure that there is no C<undef> in the array. See also L</elem>.

=head2 get_iterator_index

Usage:

 my $index = $ary->get_iterator_index;

Must return the iterator index (integer), where 0 points to the first element, 1
to the second, and so on.

Since the first call to L</get_elem> or L</elem> before any call to
L</reset_iterator> must return the first element, this means at the beginning
the iterator index must be 0.

=head2 reset_iterator

Usage:

 $ary->reset_iterator;

Can be used to reset the iterator so the next call to L</elem> or L</get_elem>
retrieves the first element.

=head1 PROVIDED METHODS

=head2 get_elem_count

Usage:

 my $count = $ary->get_elem_count;

Return the number of elements in the array. May reset the iterator (see
L</get> and L</reset_iterator>).

An array with infinite elements can return -1.

The default implementation will call L</reset_iterator>, call L</elem>
repeatedly until there is no more element, then return
L</get_iterator_index>. If your source data is already in an array or some
other form where the length is easily known, you can replace the implementation
with a more efficient one.

=head2 get_all_elems

Usage:

 my $elems = $ary->get_all_elems;

Return an arrayref containing all elements of the array. Basically:

 my $elems = [];
 $ary->reset_iterator;
 while (1) {
     my $elem;
     eval { $elem = $ary->elem };
     last if $@;
     push @$elems, $elem;
 }
 $elems;

=head2 each_elem

Usage:

 $ary->each_elem($coderef);

Call C<$coderef> for each element. If C<$coderef> returns false, will
immediately return false and skip the rest of the elements. Otherwise, will
return true. Basically:

 $ary->reset_iterator;
 my $index = 0;
 while (1) {
     my $elem;
     eval { $elem = $ary->elem };
     last if $@;
     my $res = $coderef->($elem, $ary, $index);
     return 0 unless $res;
     $index++;
 }
 return 1;

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

L<Array::Iterator> - the C<ArrayDataRole::Spec::Basic> interface is loosely
based on this.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
