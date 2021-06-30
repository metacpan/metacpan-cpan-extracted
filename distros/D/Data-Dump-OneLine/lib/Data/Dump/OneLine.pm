package Data::Dump::OneLine;

our $DATE = '2021-06-27'; # DATE
our $VERSION = '0.080'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our @ISA = qw(Data::Dmp);
our @EXPORT = (@Data::Dmp::EXPORT, 'dump1', 'dump_one_line');

*dump1 = \&Data::Dmp::dmp;
*dump_one_line = \&Data::Dmp::dmp;

1;
# ABSTRACT: Dump data structures as single-line strings

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::OneLine - Dump data structures as single-line strings

=head1 VERSION

This document describes version 0.080 of Data::Dump::OneLine (from Perl distribution Data-Dump-OneLine), released on 2021-06-27.

=head1 SYNOPSIS

 use Data::Dump::OneLine; # exports dd and dmp
 $str = dd(@list);

=head1 DESCRIPTION

It now uses L<Data::Dmp>. You should use Data::Dmp directly.

=for Pod::Coverage ^(.+)$

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <sharyanto@cpan.org>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-OneLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-OneLine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-OneLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<JSON> should also encode to a single-line string, but some data structures
(cyclical, contains globs or other special Perl data) cannot be encoded out of
the box to JSON.

L<Data::Dumper::OneLine> strives to do the same for L<Data::Dumper>, but last
time I tried it (at v0.05) it's still buggy.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2015, 2014, 2013, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
