## no critic: Subroutines::ProhibitSubroutinePrototypes
package Array::Util::MultiTarget;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-03'; # DATE
our $DIST = 'Array-Util-MultiTarget'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       mtpop
                       mtpush
                       mtsplice
                       mtremovestr
                       mtremoveallstr
                       mtremovenum
                       mtremoveallnum
               );

sub mtpop($) {
    my $arys = shift;

    my @res;
    for my $ary (@$arys) { push @res, pop @$ary }
    @res;
}

sub mtpush($@) {
    my $arys = shift;

    for my $ary (@$arys) { push @$ary, @_ }
}

sub mtsplice($$;$@) {
    my $arys = shift;
    my $offset = shift;
    my $len; $len = shift if @_;

    my @res;
    for my $ary (@$arys) {
        if (defined $len) {
            push @res, [splice @$ary, $offset, $len, @_];
        } else {
            push @res, [splice @$ary, $offset];
        }
    }
    @res;
}

sub mtremovestr {
    my $arys = shift;
    my $wanted = shift;

    my $pos;
    for my $i (0 .. $#{ $arys->[0] }) {
        if ($arys->[0][$i] eq $wanted) {
            $pos = $i; last;
        }
    }
    return unless defined $pos;

    for my $ary (@$arys) {
        splice @$ary, $pos, 1;
    }

    $pos;
}

sub mtremoveallstr {
    my $arys = shift;
    my $wanted = shift;

    my @pos;
    for my $i (0 .. $#{ $arys->[0] }) {
        if ($arys->[0][$i] eq $wanted) {
            unshift @pos, $i;
        }
    }
    return unless @pos;

    for my $ary (@$arys) {
        for (@pos) {
            splice @$ary, $_, 1;
        }
    }

    reverse @pos;
}

sub mtremovenum {
    my $arys = shift;
    my $wanted = shift;

    my $pos;
    for my $i (0 .. $#{ $arys->[0] }) {
        if ($arys->[0][$i] == $wanted) {
            $pos = $i; last;
        }
    }
    return unless defined $pos;

    for my $ary (@$arys) {
        splice @$ary, $pos, 1;
    }

    $pos;
}

sub mtremoveallnum {
    my $arys = shift;
    my $wanted = shift;

    my @pos;
    for my $i (0 .. $#{ $arys->[0] }) {
        if ($arys->[0][$i] == $wanted) {
            unshift @pos, $i;
        }
    }
    return unless @pos;

    for my $ary (@$arys) {
        for (@pos) {
            splice @$ary, $_, 1;
        }
    }

    reverse @pos;
}

1;
# ABSTRACT: Apply an operation to multiple arrays

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Util::MultiTarget - Apply an operation to multiple arrays

=head1 VERSION

This document describes version 0.001 of Array::Util::MultiTarget (from Perl distribution Array-Util-MultiTarget), released on 2023-12-03.

=head1 SYNOPSIS

 use Array::Util::MultiTarget qw(
     mtpop
     mtpush
     mtsplice
     mtremovestr
     mtremoveallstr
     mtremovenum
     mtremoveallnum
 );

=head1 DESCRIPTION

This module provides functions to perform operations on multiple arrays at once.
Some functions work best for arrays that contain parallel data, as shown in the
Synopsis.

=head1 FUNCTIONS

=head2 mtpop

Usage:

 @elems = mtpop [\@ary1, \@ary2, ...];

Pop each array and return the collected popped elements. C<@elems> will contain:

 ($popped_from_ary1, $popped_from_ary2, ...)

=head2 mtpush

Usage:

 mtpush [\@ary1, \@ary2, ...], @elems;

Push C<@elems> to each array.

=head2 mtsplice

Usage:

 @spliced = mtsplice [\@ary1, \@ary2, ...], $offset, $length, @list;
 @spliced = mtsplice [\@ary1, \@ary2, ...], $offset, $length;
 @spliced = mtsplice [\@ary1, \@ary2, ...], $offset;

Splice each array and return the collected result from C<splice()>. C<@spliced>
will contain:

 (\@spliced_elems_from_ary1, \@spliced_elems_from_ary2, ...)

=head2 mtremovestr

Usage:

 $offset = mtremovestr [\@ary1, \@ary2, ...], $needle;

Find the first occurrence of C<$needle> in C<@ary1> using C<eq> operator, then
remove it from C<@ary1> and return the offset where C<$needle> was found. After
that, remove the element at the same offset from the rest of the arrays.

If C<$needle> is not found, will return C<undef> and leave the arrays
unmodified.

TODO: add option C<$minoffset>, C<$maxoffset>.

=head2 mtremoveallstr

Usage:

 @offsets = mtremoveallstr [\@ary1, \@ary2, ...], $needle;

Find all occurrences of C<$needle> in C<@ary1> using C<eq> operator, then remove
them from C<@ary1> and return the offsets where C<$needle> were found. After
that, remove the elements at the same offsets from the rest of the arrays.

If C<$needle> is not found, will return empty list and leave the arrays
unmodified.

TODO: add option C<$minoffset>, C<$maxoffset>.

=head2 mtremovenum

Like C</mtremovestr> except comparison is done using C<==> operator instead of
C<eq>.

=head2 mtremoveallnum

Like C</mtremoveallstr> except comparison is done using C<==> operator instead
of C<eq>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Util-MultiTarget>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Util-MultiTarget>.

=head1 SEE ALSO

L<List::Util>, L<List::MoreUtils>, L<List::AllUtils>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Util-MultiTarget>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
