package ArrayDataRole::Source::LinesInDATA;

use strict;
use Role::Tiny;
use Role::Tiny::With;
with 'ArrayDataRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'ArrayDataRoles-Standard'; # DIST
our $VERSION = '0.007'; # VERSION

sub new {
    no strict 'refs'; ## no critic: TestingAndDebugging::RequireUseStrict

    my $class = shift;

    my $fh = \*{"$class\::DATA"};
    my $fhpos_data_begin = tell $fh;

    bless {
        fh => $fh,
        fhpos_data_begin => $fhpos_data_begin,
        pos => 0, # iterator
    }, $class;
}

sub get_next_item {
    my $self = shift;
    die "StopIteration" if eof($self->{fh});
    chomp(my $elem = readline($self->{fh}));
    $self->{pos}++;
    $elem;
}

sub has_next_item {
    my $self = shift;
    !eof($self->{fh});
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

sub reset_iterator {
    my $self = shift;
    seek $self->{fh}, $self->{fhpos_data_begin}, 0;
    $self->{pos} = 0;
}

sub get_item_at_pos {
    my ($self, $pos) = @_;
    $self->reset_iterator if $self->{pos} > $pos;
    while (1) {
        die "Out of range" unless $self->has_next_item;
        my $item = $self->get_next_item;
        return $item if $self->{pos} > $pos;
    }
}

sub has_item_at_pos {
    my ($self, $pos) = @_;
    return 1 if $self->{pos} > $pos;
    while (1) {
        return 0 unless $self->has_next_item;
        $self->get_next_item;
        return 1 if $self->{pos} > $pos;
    }
}

sub fh {
    my $self = shift;
    $self->{fh};
}

sub fh_min_offset {
    my $self = shift;
    $self->{fhpos_data_begin};
}

sub fh_max_offset { undef }

1;
# ABSTRACT: Role to access array data from DATA section, one line per element

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Source::LinesInDATA - Role to access array data from DATA section, one line per element

=head1 VERSION

This document describes version 0.007 of ArrayDataRole::Source::LinesInDATA (from Perl distribution ArrayDataRoles-Standard), released on 2021-12-01.

=head1 DESCRIPTION

This role expects array data in lines in the DATA section.

Note: C<get_item_at_pos()> and C<has_item_at_pos()> are slow (O(n) in worst
case) because they iterate. Caching might be added in the future to speed this
up.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<ArrayDataRole::Spec::Basic>

=head1 PROVIDED METHODS

=head2 fh

Returns the DATA filehandle.

=head2 fh_min_offset

Returns the starting position of DATA.

=head2 fh_max_offset

Returns C<undef>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayDataRoles-Standard>.

=head1 SEE ALSO

L<ArrayDataRole::Source::LinesInFile>

Other C<ArrayDataRole::Source::*>

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayDataRoles-Standard>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
