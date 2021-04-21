package ArrayData::Test::Spec::Basic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-20'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.2.0'; # VERSION

use strict;
use warnings;

use Role::Tiny::With;

with 'ArrayDataRole::Spec::Basic';

my $elems = [
    1,
    2,
    undef,
    4,
];

sub new {
    my $class = shift;
    bless {pos=>0}, $class;
}

sub _elems {
    my $self = shift;
    $elems;
}

sub get_next_item {
    my $self = shift;
    die "Out of range" unless $self->{pos} < @$elems;
    $elems->[ $self->{pos}++ ];
}

sub has_next_item {
    my $self = shift;
    $self->{pos} < @$elems;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    $self->{pos} = 0;
}

1;

# ABSTRACT: A test table data

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData::Test::Spec::Basic - A test table data

=head1 VERSION

This document describes version 0.2.0 of ArrayData::Test::Spec::Basic (from Perl distribution ArrayData), released on 2021-04-20.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayData/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
