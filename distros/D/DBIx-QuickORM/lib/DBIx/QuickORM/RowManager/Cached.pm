package DBIx::QuickORM::RowManager::Cached;
use strict;
use warnings;

our $VERSION = '0.000023';

use Carp qw/croak/;
use Scalar::Util qw/weaken/;

use DBIx::QuickORM::Affinity();

use parent 'DBIx::QuickORM::RowManager';
use Object::HashBase qw {
    +cache
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::RowManager::Cached - Row manager with a per-source identity cache.

=head1 DESCRIPTION

A L<DBIx::QuickORM::RowManager> that keeps at most one row object per primary
key per source. Rows are stored under a per-source bucket keyed by their
primary key and held weakly, so cached rows can be reused while still being
garbage collected once no longer referenced.

=head1 SYNOPSIS

    my $mgr = DBIx::QuickORM::RowManager::Cached->new(connection => $connection);

=cut

sub does_cache { 1 }

sub init {
    my $self = shift;
    $self->SUPER::init();
    $self->{+CACHE} //= {};
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $row = $mgr->do_cache_lookup($source, $fetched, $old_pk, $new_pk, $row)

Return the cached row for the source and primary key, or undef.

=cut

sub do_cache_lookup {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = @_;

    my $pk = $old_pk // $new_pk // return;
    my $scache = $self->{+CACHE}->{$source->source_orm_name} or return;

    my $cache_key = $self->cache_key($pk) // return;

    if (exists $scache->{$cache_key}) {
        return $scache->{$cache_key} if defined $scache->{$cache_key};
        $self->_purge_dead($scache);
    }

    return undef;
}

=pod

=item $row = $mgr->cache($source, $row, $old_pk, $new_pk)

Store the row in its source bucket under its new primary key (held weakly),
removing any entry under the old primary key. Returns the row, or nothing for
sources without a primary key. A row whose primary key has an undef component
cannot be keyed and is returned uncached.

=cut

sub cache {
    my $self = shift;
    my ($source, $row, $old_pk, $new_pk) = @_;

    return unless $source->primary_key;

    my $scache = $self->{+CACHE}->{$source->source_orm_name} //= {};

    if ($old_pk) {
        my $old_key = $self->cache_key($old_pk);
        delete $scache->{$old_key} if defined $old_key;
    }

    $new_pk //= [$row->primary_key_value_list];
    my $new_key = $self->cache_key($new_pk) // return $row;

    $self->_purge_dead($scache) if exists $scache->{$new_key} && !defined $scache->{$new_key};

    $scache->{$new_key} = $row;
    weaken($scache->{$new_key});
    return $row;
}

=pod

=item $row = $mgr->uncache($source, $row, $old_pk, $new_pk)

Remove and return the cached row for the given source and primary key. The
primary key is taken from the supplied keys, or from the row itself when
none are given.

=cut

sub uncache {
    my $self = shift;
    my ($source, $row, $old_pk, $new_pk) = @_;

    my $pk = $old_pk // $new_pk;
    $pk = [$row->primary_key_value_list] if $row && !$pk && $row->source->primary_key;

    # No pk, not a cachable row
    return unless $pk && @$pk;

    my $scache = $self->{+CACHE}->{$source->source_orm_name} or return;

    my $row_key = $self->cache_key($pk) // return;
    return delete $scache->{$row_key};
}

=pod

=item $key = $mgr->cache_key($pk)

Build a single cache-key string from an arrayref of primary-key values,
joining them on a separator; backslashes and separator characters inside a
value are escaped. Returns undef when any component is undef, since such a
key cannot be distinguished from an empty string.

=back

=cut

sub cache_key {
    my $self = shift;
    my ($pk) = @_;

    my $sep = chr(31);

    my @parts;
    for my $val (@$pk) {
        return undef unless defined $val;

        my $part = $val;
        $part =~ s/\\/\\\\/g;
        $part =~ s/\Q$sep\E/\\$sep/g;
        push @parts => $part;
    }

    return join $sep => @parts;
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $mgr->_purge_dead($scache)

Delete entries from a source bucket whose weakly-held row has been garbage
collected.

=back

=cut

sub _purge_dead {
    my $self = shift;
    my ($scache) = @_;

    my @dead = grep { !defined $scache->{$_} } keys %$scache;
    delete @{$scache}{@dead} if @dead;

    return;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
