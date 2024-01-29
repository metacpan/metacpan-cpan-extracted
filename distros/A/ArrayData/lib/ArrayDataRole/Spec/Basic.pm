package ArrayDataRole::Spec::Basic;

use strict;
use warnings;

use Role::Tiny;
use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-16'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.2.6'; # VERSION

# constructor
requires 'new';

# other required methods
requires 'get_item_count';

# mixin
with 'Role::TinyCommons::Iterator::Resettable';
with 'Role::TinyCommons::Collection::GetItemByPos';

# provides

my @role_prefixes = qw(ArrayDataRole Role::TinyCommons::Collection);
sub apply_roles {
    my ($obj, @unqualified_roles) = @_;

    my @roles_to_apply;
  ROLE:
    for my $ur (@unqualified_roles) {
      PREFIX:
        for my $prefix (@role_prefixes) {
            my ($mod, $modpm);
            $mod = "$prefix\::$ur";
            ($modpm = "$mod.pm") =~ s!::!/!g;
            eval { require $modpm; 1 };
            unless ($@) {
                #print "D:$mod\n";
                push @roles_to_apply, $mod;
                next ROLE;
            }
        }
        die "Can't find role '$ur' to apply (searched these prefixes: ".
            join(", ", @role_prefixes);
    }

    Role::Tiny->apply_roles_to_object($obj, @roles_to_apply);

    # return something useful
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

This document describes version 0.2.6 of ArrayDataRole::Spec::Basic (from Perl distribution ArrayData), released on 2024-01-16.

=head1 DESCRIPTION

L<ArrayData>::* modules let you iterate elements using a resettable iterator
interface (L<Role::TinyCommons::Iterator::Resettable>) as well as get elements
by position (L<Role::TinyCommons::Collection::GetItemByPos>), like what a
regular Perl array lets you.

It allows an array with infinite number of elements.

 category                     method name                note                        modifies iterator?
 --------                     -----------                -------                     ------------------
 instantiating                new(%args)                                             N/A

 iterating items              has_next_item()                                        no
                              get_next_item()                                        yes (moves forward 1 position)
                              reset_iterator()                                       yes (resets)

 iterating items (alt)        each_item()                                            yes (resets)

 getting all items            get_all_items()                                        yes (resets)

 getting item count           get_item_count()                                       yes (resets) / no (for some implementations)

 utility: applying roles      apply_roles(R1, R2, ...)                               N/A

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

From L<Role::TinyCommons::Collection::GetItemByPos>.

Should reset iterator.

=head2 has_item_at_pos

From L<Role::TinyCommons::Collection::GetItemByPos>.

Can reset iterator if required.

=head2 get_item_count

Provided by L<Role::TinyCommons::Collection::GetItemByPos>, but you can provide
a more efficient implementation.

Get number of elements of array. Must return -1 to mean an array with infinite
number of elements. Can reset iterator if required.

=head1 PROVIDED METHODS

=head2 each_item

From L<Role::TinyCommons::Collection::GetItemByPos>. But if you have an infinite
array data, this method will loop endlessly; you can provide your own
implementation to prevent this from happening.

=head2 get_all_items

From L<Role::TinyCommons::Collection::GetItemByPos>. But if you have an infinite
array data, this method will loop and collect endlessly; you can provide your
own implementation to prevent this from happening.

=head2 apply_roles

Usage:

 $obj->apply_roles('R1', 'R2', ...)

Apply roles to object. R1, R2, ... are unqualified role names that will be
searched under C<ArrayDataRole::*> or C<Role::TinyCommons::Collection::*>
namespace. It's a convenience shortcut for C<< Role::Tiny->apply_roles_to_object
>>.

Return the object, so you can do something like this:

 my $obj = ArrayData::Word::ID::KBBI->new->apply_roles('FindItem::Iterator', 'PickItems::RandomPos');

 my $obj = ArrayData::Word::ID::KBBI->new->apply_roles('BinarySearch::LinesInHandle');

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

=head1 SEE ALSO

L<Role::TinyCommons::Iterator::Resettable>

L<Role::TinyCommons::Collection::GetItemByPos>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

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

This software is copyright (c) 2024, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
