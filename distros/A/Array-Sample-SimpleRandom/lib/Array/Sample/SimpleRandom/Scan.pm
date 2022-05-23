package Array::Sample::SimpleRandom::Scan;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-20'; # DATE
our $DIST = 'Array-Sample-SimpleRandom'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(sample_simple_random_no_replacement);

sub sample_simple_random_no_replacement {
    require Array::Pick::Scan;

    my ($ary, $n) = @_;
    Array::Pick::Scan::random_item($ary, $n);
}

1;
# ABSTRACT: Simple random sampling from an array (scan algorithm)

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Sample::SimpleRandom::Scan - Simple random sampling from an array (scan algorithm)

=head1 VERSION

This document describes version 0.001 of Array::Sample::SimpleRandom::Scan (from Perl distribution Array-Sample-SimpleRandom), released on 2022-05-20.

=head1 SYNOPSIS

 use Array::Sample::SimpleRandom::Scan qw(sample_simple_random_no_replacement);

 sample_simple_random_no_replacement([0,1,2,3,4,5], 1); # => (3)
 sample_simple_random_no_replacement([0,1,2,3,4,5], 1); # => (5)

 sample_simple_random_no_replacement([0,1,2,3,4,5], 3); # => (4,1,5)
 sample_simple_random_no_replacement([0,1,2,3,4,5], 3); # => (1,4,3)

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 sample_simple_random_no_replacement

Usage:

 my @items = sample_simple_random_no_replacement(\@ary, $n);

This function takes an array reference (C<\@ary>) and the number of samples
requested (C<$n>) and will return a list of elements. Samples will be picked
without replacement, e.g. an element will not be chosen more than once (note
that it still possible to return duplicate values if the original array contain
duplicate values).

This function is the same as the one in L<Array::Sample::SimpleRandom>, except
that it uses a scan algorithm from L<Array::Pick::Scan>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Sample-SimpleRandom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Sample-SimpleRandom>.

=head1 SEE ALSO

L<Array::Sample::SimpleRandom>

Other sampling methods: L<Array::Sample::Partition>, L<Array::Sample::SysRand>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Sample-SimpleRandom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
