package ArrayData::Array;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-03'; # DATE
our $DIST = 'ArrayDataRoles-Standard'; # DIST
our $VERSION = '0.005'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;
with 'ArrayDataRole::Source::Array';

1;
# ABSTRACT: Get array data from Perl array

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData::Array - Get array data from Perl array

=head1 VERSION

This document describes version 0.005 of ArrayData::Array (from Perl distribution ArrayDataRoles-Standard), released on 2021-05-03.

=head1 SYNOPSIS

 use ArrayData::Array;

 my $ary = ArrayData::Array->new(
     array => [1,2,3],
 );

=head1 DESCRIPTION

This is an C<ArrayData::> module to get array elements from a Perl array.

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

L<ArrayData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
