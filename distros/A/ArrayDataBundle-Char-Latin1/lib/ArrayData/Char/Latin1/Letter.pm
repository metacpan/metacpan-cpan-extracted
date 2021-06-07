package ArrayData::Char::Latin1::Letter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-20'; # DATE
our $DIST = 'ArrayDataBundle-Char-Latin1'; # DIST
our $VERSION = '0.003'; # VERSION

use Role::Tiny::With;
with 'ArrayDataRole::Source::LinesInDATA';
with 'Role::TinyCommons::Collection::FindItem::Iterator';  # add find_item() and has_item()
with 'Role::TinyCommons::Collection::PickItems::Iterator'; # add pick_items(), pick_item()

# STATS

1;
# ABSTRACT: Latin1 letters

=pod

=encoding UTF-8

=head1 NAME

ArrayData::Char::Latin1::Letter - Latin1 letters

=head1 VERSION

This document describes version 0.003 of ArrayData::Char::Latin1::Letter (from Perl distribution ArrayDataBundle-Char-Latin1), released on 2021-05-20.

=head1 SYNOPSIS

 use ArrayData::Char::Latin1::Letter;

 my $ary = ArrayData::Char::Latin1::Letter->new;

 # Iterate the elements
 $ary->reset_iterator;
 while ($ary->has_next_item) {
     my $element = $ary->get_next_item;
     ... # do something with the element
 }

 # Another way to iterate
 $ary->each_item(sub { my ($item, $obj, $pos) = @_; ... }); # return false in anonsub to exit early

 # Get elements by position (array index)
 my $element = $ary->get_item_at_pos(0);  # get the first element
 my $element = $ary->get_item_at_pos(90); # get the 91th element, will die if there is no element at that position.

 # Get number of elements in the list
 my $count = $ary->get_item_count;

 # Get all elements from the list
 my @all_elements = $ary->get_all_items;

 # Find an item.
 my @found = $ary->find_item(item => 'foo');
 my $has_item = $ary->has_item('foo'); # bool

 # Pick one or several random elements.
 my $element = $ary->pick_item;
 my @elements = $ary->pick_items(n=>3);

=head1 DESCRIPTION

For testing only.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayDataBundle-Char-Latin1>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayDataBundle-Char-Latin1>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayDataBundle-Char-Latin1/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
A
B
C
D
E
F
G
H
I
J
K
L
M
N
O
P
Q
R
S
T
U
V
W
X
Y
Z
a
b
c
d
e
f
g
h
i
j
k
l
m
n
o
p
q
r
s
t
u
v
w
x
y
z
