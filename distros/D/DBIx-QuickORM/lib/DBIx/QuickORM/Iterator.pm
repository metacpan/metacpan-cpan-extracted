package DBIx::QuickORM::Iterator;
use strict;
use warnings;

our $VERSION = '0.000026';

use Carp qw/croak/;

sub new;

use Object::HashBase qw{
    generator
    items
    generator_done
    index
    +ready
    +is_ready
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Iterator - Lazy, caching iterator over a generator.

=head1 DESCRIPTION

Wraps a generator coderef that yields one item per call and returns undef
when exhausted. Items are pulled on demand and cached, so the iterator can
be walked, reset, and re-walked. An optional readiness coderef supports
async result checks.

=head1 SYNOPSIS

    my $iter = DBIx::QuickORM::Iterator->new(\&generator, \&ready);

    while (defined(my $item = $iter->next)) { ... }

    my @all = $iter->list;

=head1 ATTRIBUTES

=over 4

=item generator

Coderef yielding one item per call, undef when exhausted.

=item items

Arrayref of items pulled from the generator so far.

=item generator_done

True once the generator has signalled exhaustion.

=item index

Current position for C<next>.

=item ready

Optional coderef returning true once results are available.

=back

=cut

sub new {
    my $class = shift;
    my ($gen, $ready) = @_;

    my $self = bless({GENERATOR() => $gen, READY() => $ready}, $class);
    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    croak "Generator is required" unless $self->{+GENERATOR};

    croak "Generator must be a code reference, got '$self->{+GENERATOR}'" unless ref($self->{+GENERATOR}) eq 'CODE';

    $self->{+INDEX} = 0;
    $self->{+ITEMS} = [];

    $self->{+GENERATOR_DONE} = 0;
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $item = $iter->next

Return the next item and advance, or undef when exhausted.

=cut

sub next {
    my $self = shift;

    my $idx = $self->{+INDEX};
    my $set = $self->{+ITEMS};

    unless ($idx < @$set) {
        return if $self->{+GENERATOR_DONE};
        return unless $self->_grow;
    }

    $self->{+INDEX}++;
    return $set->[$idx];
}

=pod

=item $item = $iter->first

Reset to the start and return the first item.

=cut

sub first {
    my $self = shift;
    $self->{+INDEX} = 0;
    $self->next;
}

=pod

=item $item = $iter->last

Exhaust the generator and return the last item (or undef if none).

=cut

sub last {
    my $self = shift;

    my $set = $self->{+ITEMS};

    $self->_grow until $self->{+GENERATOR_DONE};

    $self->{+INDEX} = scalar @$set;

    return unless @$set;
    return $set->[-1];
}

=pod

=item @items = $iter->list

Exhaust the generator and return every item.

=cut

sub list {
    my $self = shift;
    local $self->{+INDEX} = 0;

    my $set = $self->{+ITEMS};
    $self->_grow until $self->{+GENERATOR_DONE};

    return @$set;
}

=pod

=item $bool = $iter->ready

True when results are available. Always true unless a readiness coderef
was supplied.

=back

=cut

sub ready {
    my $self = shift;
    my $cb = $self->{+READY} or return 1;
    return $self->{+IS_READY} ||= $cb->();
}

# Pull one more item from the generator into the cache; returns true if an
# item was added, false once the generator is exhausted.
sub _grow {
    my $self = shift;

    return 0 if $self->{+GENERATOR_DONE};

    my $add = $self->{+GENERATOR}->();

    unless (defined $add) {
        $self->{+GENERATOR_DONE} = 1;
        return 0;
    }

    push @{$self->{+ITEMS}} => $add;
    return 1;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
