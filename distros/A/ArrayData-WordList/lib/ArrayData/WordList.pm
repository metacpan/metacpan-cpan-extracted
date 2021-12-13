package ArrayData::WordList;

use strict;

use Role::Tiny::With;
with 'ArrayDataRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'ArrayData-WordList'; # DIST
our $VERSION = '0.001'; # VERSION

# STATS

sub new {
    my ($class, %args) = @_;

    my $wlname = delete $args{wordlist};
    defined $wlname or die "Please specify wordlist";

    require Module::Load::Util;
    my $wl = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"WordList"}, $wlname);

    bless {
        wl => $wl,
        pos => 0, # iterator
    }, $class;
}

sub reset_iterator {
    my $self = shift;
    $self->{wl}->reset_iterator;
    $self->{pos} = 0;
}

sub get_next_item {
    my $self = shift;
    if (exists $self->{buf}) {
        $self->{pos}++;
        return delete $self->{buf};
    } else {
        my $word = $self->{pos} == 0 ? $self->{wl}->first_word : $self->{wl}->next_word;
        die "StopIteration" unless defined $word;
        $self->{pos}++;
        $word;
    }
}

sub has_next_item {
    my $self = shift;
    if (exists $self->{buf}) {
        return 1;
    }
    my $word = $self->{pos} == 0 ? $self->{wl}->first_word : $self->{wl}->next_word;
    return 0 unless defined $word;
    $self->{buf} = $word;
    1;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
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

1;
# ABSTRACT: Array data from a WordList::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData::WordList - Array data from a WordList::* module

=head1 VERSION

This document describes version 0.001 of ArrayData::WordList (from Perl distribution ArrayData-WordList), released on 2021-12-01.

=head1 DESCRIPTION

This module gets array data from a C<WordList::> module. It is a bridge between
L<WordList> and L<ArrayData>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData-WordList>.

=head1 SEE ALSO

L<WordList::ArrayData>

L<ArrayData>

L<WordList>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayData-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
