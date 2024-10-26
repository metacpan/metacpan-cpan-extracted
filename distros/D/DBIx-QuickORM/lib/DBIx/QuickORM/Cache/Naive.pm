package DBIx::QuickORM::Cache::Naive;
use strict;
use warnings;

our $VERSION = '0.000001';

use parent 'DBIx::QuickORM::Cache';

use Carp qw/croak/;
use Scalar::Util qw/weaken blessed/;

sub find_row {
    my $self = shift;
    my ($source, $data) = @_;

    my $key = $self->cache_key($source, $data) or return undef;
    my $ref = $self->cache_ref($source, $key);

    return undef unless $$ref;
    return $$ref;
}

sub add_row {
    my $self = shift;
    my ($row) = @_;
    return $self->cache_source_row($row->source, $row);
}

sub add_source_row {
    my $self = shift;
    my ($source, $row, %params) = @_;

    $params{weak} //= 1;

    my $key = $self->cache_key($source, $row) or return undef;
    my $ref = $self->cache_ref($source, $key);

    $$ref = $row;
    weaken($$ref) if $params{weak};

    return $row;
}

sub clear {
    my $self = shift;
    $self->remove_source($_) for keys %{$self};
}

sub prune {
    my $self = shift;
    $self->prune_source($_) for keys %{$self};
}

sub uncache_source_row {
    my $self = shift;
    my ($source, $row) = @_;

    my $ref;
    my $key = $self->cache_key($source, $row) or return undef;
    ($ref, $key) = $self->cache_ref($source, $key, parent => 1);

    return unless ${$ref}->{$key};

    croak "Found wrong object in cache (${$ref}->{$key} vs $row)" unless $row == ${$ref}->{$key};
    delete ${$ref}->{$key};

    $row->uncache();

    return $row;
}

sub remove_source_item {
    my $self = shift;
    my ($source, $data) = @_;

    my $ref;
    my $key = $self->cache_key($source, $data) or return undef;
    ($ref, $key) = $self->cache_ref($source, $key, parent => 1);

    return unless ${$ref}->{$key};

    delete ${$ref}->{$key};
}

sub _source_cache {
    my $self = shift;
    my ($source, $act) = @_;

    return unless $self->{$source};

    my @sets = ([$self, $source, $self->{$source}]);
    while (my $set = shift @sets) {
        my ($parent, $key, $item) = @$set;

        next if $act->($set);
        next unless $item;
        next if blessed($item) && $item->isa('DBIx::QuickORM::Row');

        push @sets => map { [$item, $_, $item->{$_}] } grep { $item->{$_} } keys %$item;
    }
}

sub prune_source {
    my $self = shift;
    my ($source) = @_;

    $self->_source_cache(
        $source => sub {
            my $set = shift;
            my ($parent, $key, $item) = @$set;

            if (!$item) {
                delete $parent->{$key};    # Prune empty hash keys
                return 1;
            }

            if (blessed($item) && $item->isa('DBIx::QuickORM::Row')) {
                @$set = ();
                my $cnt = Internals::SvREFCNT(%$item);

                next if $cnt > 3;                                 # The cache copy, the copy here, and the _source_cache one
                next if $cnt == 2 && is_weak($parent->{$key});    # in cache weakly

                delete $parent->{$key};
                return 1;
            }

            return 0;
        }
    );
}

sub remove_source {
    my $self = shift;
    my ($source) = @_;

    $self->_source_cache(
        $source => sub {
            my $set = shift;
            my ($parent, $key, $item) = @$set;

            return 0 unless $item;
            return 0 unless blessed($item) && $item->isa('DBIx::QuickORM::Row');
            delete $parent->{$key};
            $item->uncache();
            return 1;
        }
    );

    delete $self->{$source};

    return;
}

sub cache_key {
    my $self = shift;
    my ($source, $data) = @_;

    my $table = $source->table;
    my $pk_fields = $table->primary_key;
    return unless $pk_fields && @$pk_fields;

    my $pk_data;

    if (blessed($data) && $data->isa('DBIx::QuickORM::Row')) {
        $pk_data = $data->stored_primary_key // {};
    }
    else {
        $pk_data = $data;
    }

    return [ map { $pk_data->{$_} // return } @$pk_fields ];
}

sub cache_ref {
    my $self = shift;
    my ($source, $keys, %params) = @_;

    my ($prev, $key);
    my $ref;
    for my $ck ("$source", @$keys) {
        if ($ref) {
            ${$ref} //= {};
            $prev = $ref;
            $key  = $ck;
            $ref  = \(${$ref}->{$ck});
        }
        else {
            $prev = $ref;
            $key  = $ck;
            $ref  = \($self->{$ck});
        }
    }

    return ($prev, $key) if $params{parent};

    return $ref;
}

1;
