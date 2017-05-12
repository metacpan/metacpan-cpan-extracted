package DBIx::ObjectMapper::Session::UnitOfWork;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Scalar::Util qw(refaddr blessed);
use Log::Any qw($log);
use Try::Tiny;

#my $in_global_destruction = 0;

sub new {
    my ( $class, $cache, $search, $change_checker, $option ) = @_;
    bless {
        query_cnt      => 0,
        search         => $search,
        cache          => $cache || undef,
        change_checker => $change_checker,
        objects        => +[],
        map_objects    => +{},
        del_objects    => +{},
        option         => $option || +{},
    }, $class;
}

sub query_cnt      { $_[0]->{query_cnt} }
sub search         { $_[0]->{search}->new(@_) }
sub cache          { $_[0]->{cache} }
sub change_checker { $_[0]->{change_checker} }

sub autoflush      {
    my $self = shift;
    if( @_ ) {
        $self->{option}{autoflush} = shift;
    }
    return $self->{option}{autoflush};
}

sub get {
    my ( $self, $t_class, $id, $option ) = @_;
    my $class_mapper = $t_class->__class_mapper__;

    my ( $key, @cond ) = $class_mapper->get_unique_condition($id);

    if( my $eagerload = $option->{eagerload} ) {
        my $attr = $class_mapper->attributes;
        my @eagerload
            = ref($eagerload) eq 'ARRAY' ? @{$eagerload} : ($eagerload);
        return $self->search($t_class)
                    ->eager(map{ $attr->p($_) } @eagerload)
                    ->filter(@cond)
                    ->execute->first;
    }
    elsif( my $cached_obj = $self->_get_cache($key) ) {
        $log->info("{UnitOfWork} Cache Hit: $key");
        if( $option->{share_object} || $self->{option}{share_object} ) {
            return $cached_obj;
        }
        else {
            my $result = $cached_obj->__mapper__->reducing;
            return $cached_obj->__class_mapper__->mapping(
                $result,
                $self,
            );
        }
    }
    else {
        my $obj = $class_mapper->find( \@cond, $self )
            || return;
        $self->{query_cnt}++;
        return $self->add_storage_object($obj);
    }
}

sub add_storage_object {
    my ( $self, $obj ) = @_;
    confess "the parameter should be a blessed object." unless blessed $obj;

    my $mapper = $obj->__mapper__;
    my $cache_key = $mapper->primary_cache_key;

    if ( $self->{option}{share_object}
        and my $cache_obj = $self->_get_cache($cache_key) )
    {
        return $cache_obj;
    }
    else {
        $mapper->change_status( 'persistent', $self );
        $self->add($obj);
        return $obj;
    }
}

sub add {
    my ( $self, $obj ) = @_;
    confess "the parameter should be a blessed object." unless blessed $obj;

    my $mapper = $obj->__mapper__;
    $mapper->change_status( 'pending', $self ) if $mapper->is_transient;
    # detached,expiredの場合はflushのところで無視される
    unless( exists $self->{map_objects}->{refaddr($obj)} ) {
        $self->_set_cache($mapper);
        push @{$self->{objects}}, $obj;
        $self->{map_objects}->{refaddr($obj)} = $#{$self->{objects}};
    }

    return $obj;
}

sub delete {
    my ( $self, $obj ) = @_;
    confess "the parameter should be a blessed object." unless blessed $obj;

    my $id = refaddr($obj);
    my $elm = $self->{map_objects}->{$id};
    $self->{objects}->[$elm] = undef;
    push @{$self->{objects}}, $obj;
    $self->{map_objects}->{$id} = $self->{del_objects}->{$id} = $elm;

    return $obj;
}

sub detach {
    my ( $self, $obj ) = @_;
    confess "the parameter should be a blessed object." unless blessed $obj;
    my $mapper = $obj->__mapper__;
    $mapper->change_status('detached');
}

sub has_changed {
    my $self = shift;
    for my $obj (@{$self->{objects}}) {
        next unless $obj;
        my $mapper = $obj->__mapper__;
        my $id = refaddr($obj);

        if( $mapper->is_pending ) {
            return 1;
        }
        elsif( $mapper->is_persistent ) {
            return 1 if exists $self->{del_objects}->{$id};
            return 1 if $mapper->is_modified;
        }
    }
    return;
}

sub flush {
    my ( $self ) = @_;

    my @delete;
    my %delete_check;
    my @errors;
    for my $obj (@{$self->{objects}}) {
        next unless $obj;
        my $mapper = $obj->__mapper__;
        my $id = refaddr($obj);

        try {
            if( $mapper->is_pending ) {
                $mapper->save();
            }
            elsif( $mapper->is_persistent ) {
                if( exists $self->{del_objects}->{$id} ) {
                    delete $self->{del_objects}->{$id};
                    unless( $delete_check{$mapper->primary_cache_key} ) {
                        $delete_check{$mapper->primary_cache_key} = 1;
                        $mapper->delete();
                    }
                }
                elsif( $mapper->is_modified ) {
                    $mapper->update();
                }
            }
        } catch {
            push @errors, $_[0];
        }
    }

    die join("\n", @errors) if @errors;
    return 1;
}

sub _get_cache {
    my ( $self, $key ) = @_;
    return unless $self->cache; # no_cache
    return $self->cache->get($key);
}

sub _set_cache {
    my ( $self, $mapper ) = @_;

    return unless $self->cache; # no_cache

    for my $key ( $mapper->cache_keys ) {
        $log->info("{UnitOfWork} Cache Set: $key") if $ENV{MAPPER_DEBUG};
        $self->cache->set( $key => $mapper->instance );
    }
}

sub _clear_cache {
    my ( $self, $mapper ) = @_;
    return unless $self->cache; # no_cache

    for my $key ( $mapper->cache_keys ) {
        $log->info("{UnitOfWork} Cache Remove: $key ") if $ENV{MAPPER_DEBUG};
        $self->cache->remove( $key );
    }
}

sub demolish {
    my $self = shift;
    $self->flush;
    for my $obj ( @{ $self->{objects} } ) {
        next unless $obj;
        $obj->__mapper__->demolish;
    }
    $self->{objects}     = +[];
    $self->{map_objects} = +{};
    $self->{del_objects} = +{};

    #$self->cache->clear;
    $self->{cache} = undef;
}

sub DESTROY {
    my $self = shift;
    $self->demolish;
    warn "DESTROY $self" if $ENV{MAPPER_DEBUG};
}

#END{
#    $in_global_destruction = 1;
#}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Session::UnitOfWork

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

