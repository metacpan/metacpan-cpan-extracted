package ArrayDataRole::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-20'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.2.0'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

# constructor
requires 'new';

# mixin
with 'Role::TinyCommons::Iterator::Resettable';

###

1;
# ABSTRACT: Required methods for all ArrayData::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Spec::Basic - Required methods for all ArrayData::* modules

=head1 VERSION

This document describes version 0.2.0 of ArrayDataRole::Spec::Basic (from Perl distribution ArrayData), released on 2021-04-20.

=head1 DESCRIPTION

The basic interface of an ArrayData module is a resettable iterator
(L<Role::TinyCommons::Iterator::Resettable>). You can call L</reset_iterator> to
jump to the first element, then call L</get_next_item> repeatedly
to get elements one at a time until all the elements are retrieved. If you need
to go back to the first element, you can call L</reset_iterator> again.

=head1 ROLES MIXED IN

L<Role::TinyCommons::Iterator::Resettable>

=head1 REQUIRED METHODS

=head2 new

Usage:

 my $ary = ArrayData::Foo->new([ %args ]);

Constructor. Must accept a pair of argument names and values.

=head1 PROVIDED METHODS

No additional provided methods.

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
