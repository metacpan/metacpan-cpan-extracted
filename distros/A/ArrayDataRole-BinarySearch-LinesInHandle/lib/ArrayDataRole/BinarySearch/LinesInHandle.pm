package ArrayDataRole::BinarySearch::LinesInHandle;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-07'; # DATE
our $DIST = 'ArrayDataRole-BinarySearch-LinesInHandle'; # DIST
our $VERSION = '0.002'; # VERSION

use Role::Tiny;
use Role::Tiny::With;

with 'Role::TinyCommons::BinarySearch::LinesInHandle';

1;
# ABSTRACT: Provide has_item() that uses binary search

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::BinarySearch::LinesInHandle - Provide has_item() that uses binary search

=head1 VERSION

This document describes version 0.002 of ArrayDataRole::BinarySearch::LinesInHandle (from Perl distribution ArrayDataRole-BinarySearch-LinesInHandle), released on 2021-05-07.

=head1 SYNOPSIS

For example, to use with classes that use L<ArrayDataRole::Spec::Basic> and
support C<apply_roles()>:

 my $obj = ArrayData::Word::ID::KBBI->new;
 $obj->has_item('kuda'); # uses linear search by iterating

 $obj = ArrayData::Word::ID::KBBI->new->apply_roles('BinarySearch::LinesInHandle');
 $obj->has_item('kuda'); # now uses binary search

=head1 DESCRIPTION

This is an alias for L<Role::TinyCommons::BinarySearch::LinesInHandle>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayDataRole-BinarySearch-LinesInHandle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayDataRole-BinarySearch-LinesInHandle>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayDataRole-BinarySearch-LinesInHandle/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Role::TinyCommons::BinarySearch::LinesInHandle>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
