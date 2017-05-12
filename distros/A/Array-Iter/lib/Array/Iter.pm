package Array::Iter;

our $DATE = '2015-12-23'; # DATE
our $VERSION = '0.01'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(array_iter list_iter);

sub array_iter {
    my $ary = shift;
    my $i = 0;
    sub {
        if ($i < @$ary) {
            return $ary->[$i++];
        } else {
            return undef;
        }
    };
}

sub list_iter {
    array_iter([@_]);
}

1;
# ABSTRACT: Generate a coderef iterator for an array

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Iter - Generate a coderef iterator for an array

=head1 VERSION

This document describes version 0.01 of Array::Iter (from Perl distribution Array-Iter), released on 2015-12-23.

=head1 SYNOPSIS

  use Array::Iter qw(array_iter list_iter);

  my $iter = array_iter([1,2,3,4,5]);
  while (my $val = $iter->()) { ... }

  $iter = list_iter(1,2,3,4,5);
  while (my $val = $iter->()) { ... }

=head1 DESCRIPTION

This module provides a simple iterator which is a coderef that you can call
repeatedly to get elements of a list/array. When the elements are exhausted, the
coderef will return undef. No class/object involved.

The principle is very simple and you can do it yourself with:

 my $iter = do {
     my $i = 0;
     sub {
         if ($i < @$ary) {
             return $ary->[$i++];
         } else {
             return undef;
         }
     };
  }

Caveat: if list/array contains an C<undef> element, it cannot be distinguished
with an exhausted iterator.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Array::Iterator>, which also lists some other related modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Iter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
