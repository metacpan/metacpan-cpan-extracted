package ArrayData::DBI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-25'; # DATE
our $DIST = 'ArrayDataRoles-Standard'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;
with 'ArrayDataRole::Source::DBI';

1;
# ABSTRACT: Get array data from DBI

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData::DBI - Get array data from DBI

=head1 VERSION

This document describes version 0.004 of ArrayData::DBI (from Perl distribution ArrayDataRoles-Standard), released on 2021-04-25.

=head1 SYNOPSIS

 use ArrayData::DBI;

 my $ary = ArrayData::DBI->new(
     sth           => $dbh->prepare("SELECT foo FROM mytable"),
     row_count_sth => $dbh->prepare("SELECT COUNT(*) FROM mytable"),
 );

 # or
 my $ary = ArrayData::DBI->new(
     dsn           => "DBI:mysql:database=mydb",
     user          => "...",
     password      => "...",
     table         => "mytable",
     column        => "mycolumn",
 );

=head1 DESCRIPTION

This is an C<ArrayData::> module to get array elements from a L<DBI> query.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI>

L<ArrayData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
