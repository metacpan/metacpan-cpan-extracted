package ArrayData::Test::Spec::Basic;

use strict;
use warnings;

use Role::Tiny::With;

with 'ArrayDataRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-16'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.2.6'; # VERSION

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
    die "StopIteration" unless $self->{pos} < @$elems;
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

sub get_item_at_pos {
    my ($self, $pos) = @_;
    if ($pos < 0) {
        die "Out of range" unless -$pos <= @$elems;
    } else {
        die "Out of range" unless $pos < @$elems;
    }
    $elems->[ $pos ];
}

sub has_item_at_pos {
    my ($self, $pos) = @_;
    if ($pos < 0) {
        return -$pos <= @$elems ? 1:0;
    } else {
        return $pos < @$elems ? 1:0;
    }
}

1;

# ABSTRACT: A test array data

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData::Test::Spec::Basic - A test array data

=head1 VERSION

This document describes version 0.2.6 of ArrayData::Test::Spec::Basic (from Perl distribution ArrayData), released on 2024-01-16.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

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
