package ArrayDataRole::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.2.2'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

# constructor
requires 'new';

# mixin
with 'Role::TinyCommons::Iterator::Resettable';
with 'Role::TinyCommons::Collection::GetItemByPos';

# provides

sub apply_roles {
    my ($obj, @ad_roles) = @_;
    Role::Tiny->apply_roles_to_object(
        $obj, map { "ArrayDataRole::$_" } @ad_roles);
    $obj;
}

###

1;
# ABSTRACT: Required methods for all ArrayData::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Spec::Basic - Required methods for all ArrayData::* modules

=head1 VERSION

This document describes version 0.2.2 of ArrayDataRole::Spec::Basic (from Perl distribution ArrayData), released on 2021-05-07.

=head1 DESCRIPTION

L<ArrayData>::* modules let you iterate elements using a resettable iterator
interface (L<Role::TinyCommons::Iterator::Resettable>) as well as get elements
by position (L<Role::TinyCommons::Collection::GetItemByPos>), like what a
regular Perl array lets you.

=head1 ROLES MIXED IN

L<Role::TinyCommons::Iterator::Resettable>

L<Role::TinyCommons::Collection::GetItemByPos>

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $ary = ArrayData::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head2 get_next_item

From L<Role::TinyCommons::Iterator::Resettable>.

=head2 has_next_item

From L<Role::TinyCommons::Iterator::Resettable>.

=head2 reset_iterator

From L<Role::TinyCommons::Iterator::Resettable>.

=head2 get_item_at_pos

From L<Role::TinyCommons::Iterator::GetItemByPos>.

=head2 has_item_at_pos

From L<Role::TinyCommons::Iterator::GetItemByPos>.

=head1 PROVIDED METHODS

=head2 apply_roles

Usage:

 $obj->apply_roles('R1', ...)

Apply ArrayDataRole::* roles (ArrayDataRole::R1, ...) to object. It's basically
a shortcut for:

 Role::Tiny->apply_roles_to_object($obj, 'ArrayDataRole::R1', ...);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayData/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::Iterator::Resettable>

L<Role::TinyCommons::Collection::GetItemByPos>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
