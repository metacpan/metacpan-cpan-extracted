package DBIx::QuickORM::RowManager::Cached;
use strict;
use warnings;

our $VERSION = '0.000015';

use Carp qw/croak/;
use Scalar::Util qw/weaken/;

use DBIx::QuickORM::Affinity();

use parent 'DBIx::QuickORM::RowManager';
use DBIx::QuickORM::Util::HashBase qw {
    +cache
};

sub does_cache { 1 }

sub init {
    my $self = shift;
    $self->SUPER::init();
    $self->{+CACHE} //= {};
}

sub do_cache_lookup {
    my $self = shift;
    my ($source, $fetched, $old_pk, $new_pk, $row) = @_;

    my $pk = $old_pk // $new_pk // return;
    my $scache = $self->{+CACHE}->{$source->source_orm_name} or return;

    my $cache_key = $self->cache_key($pk);

    return $scache->{$cache_key} // undef;
}

sub cache {
    my $self = shift;
    my ($source, $row, $old_pk, $new_pk) = @_;

    my $scache = $self->{+CACHE}->{$source->source_orm_name} //= {};

    delete $scache->{$self->cache_key($old_pk)} if $old_pk;

    return unless $source->primary_key;

    $new_pk //= [$row->primary_key_value_list];
    my $new_key = $self->cache_key($new_pk);
    $scache->{$new_key} = $row;
    weaken($scache->{$new_key});
    return $row;
}

sub uncache {
    my $self = shift;
    my ($source, $row, $old_pk, $new_pk) = @_;

    my $pk = $old_pk // $new_pk;
    if ($row && !$pk && $row->primary_key) {
        $pk = $row->primary_key_hashref;
    }

    # No pk, not a cachable row
    return unless $pk && @$pk;

    my $scache = $self->{+CACHE}->{$source->source_orm_name} or return;

    my $row_key = $self->cache_key($pk);
    return delete $scache->{$row_key};
}

sub cache_key {
    my $self = shift;
    my ($pk) = @_;

    my $sep = chr(31);
    join $sep => map { my $x = $_; $x =~ s/\Q$sep\E/\\$sep/; $x } @$pk;
}

1;
