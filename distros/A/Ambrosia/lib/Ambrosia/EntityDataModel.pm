package Ambrosia::EntityDataModel;
use strict;
use warnings;

use Ambrosia::Assert;
use Ambrosia::core::Nil;
use Ambrosia::error::Exceptions;
use Ambrosia::QL;
use Ambrosia::Utils::Util qw/pare_list/;
use Ambrosia::DataProvider;

use Ambrosia::Utils::Enumeration property => _state => NEW => 0, LOADED => 1, UPDATED => 2, SAVED => 3;
#NEW      Новый объект. Информация в storage не отправлялась.
#LOADED   Объект прочитан из storage.
#UPDATED  Объект взят из хранилища и изменен.
#SAVED    Информация об объекте сохранена в storage.

use Ambrosia::Meta;
class abstract
{
    private => [qw/_state/],
};

our $VERSION = 0.010;

################################################################################

sub _map() { return shift->__AMBROSIA_ALIAS_FIELDS__ || {} }

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    if ( $self->key_value() )
    {
        $self->SET_LOADED;
    }
    else
    {
        $self->SET_NEW;
    }
}

################################################################################
#  statics
################################################################################
sub handler
{
    storage()->driver($_[0]->driver_type(), $_[0]->source_name())->handler()
}

sub driver_type
{
    return 'DBI';
}

sub source_name
{
}

sub table
{
}

sub source_path
{
    my $driver = storage()->driver($_[0]->driver_type(), $_[0]->source_name());
    return $driver->catalog, $driver->schema, $_[0]->table();
}

#Редактируемые поля (сохраняемые в БД). По умолчанию все public поля класса
#Edited fields (storage in Data Source). Default all publick fields of class.
sub edit_fields
{
    return $_[0]->fields();
}

sub fields_mapping()
{
    my $proto = shift;
    return map { $proto->_map->{$_} || $_ } $proto->edit_fields();
}

#Возвращает имя ключа класса.
#Соответствует автоинкрементному полю в БД.
#Если поле не автоинкрементное используем key
sub primary_key
{
}

#Сотставной ключ
#Поведение по-умолчанию. Может быть переопределено в дочернем классе.
sub key
{
    $_[0]->primary_key;
}

################################################################################
sub id_value
{
    my $self = shift;
    my $key_name = $self->key();
    if ( ref $key_name )
    {
        return [ map { $self->$_ } @$key_name ];
    }
    else
    {
        return $self->$key_name
    }
}

sub key_value
{
    goto &id_value;
}

sub primary_key_value
{
    my $self = shift;
    my $pk_name = $self->primary_key();
    return $self->$pk_name;
}

################################################################################

sub need_insert
{
    return $_[0]->IS_NEW;
}

sub need_update
{
    return $_[0]->IS_LOADED || $_[0]->IS_UPDATED
}

sub id_value_from_hash
{
    my $proto = shift;
    my $h = shift;
    my $key_name = $proto->key();

    if ( ref $key_name )
    {
        return [ @$h{@$key_name} ];
    }
    else
    {
        return $h->{$key_name};
    }
}

################################################################################
#   END
################################################################################
sub get_cache_code
{
    my $proto = shift;

    if ( my $class = ref $proto )
    {
        my $id = $proto->key_value();
        return $class . '_' . join '_', (ref $id ? @$id : $id);
    }
    else
    {
        my $id = shift();
        if ( defined $id )
        {
            return $proto . '_' . join '_', (ref $id ? @$id : $id);
        }
        else
        {
            die 'Bad usage get_cache_code: ' . $proto . '; '
                . join('; ', caller(0), "\n")
                . join('; ', caller(1), "\n")
                . join('; ', caller(2), "\n");
        }
    }
}

sub after_load
{
    @_;
}

sub list
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $offset = shift;
    my $limit = shift;
    my $count = shift;

    my $driver = storage->driver($class->driver_type, $class->source_name);

    assert {$driver} 'Not defined driver';
    return new Ambrosia::core::Nil unless $driver;

    my $source_path = join '_', grep defined $_, $class->source_path();

    my $entity;
    my $query = Ambrosia::QL
        ->from([$class->source_path()], \$entity)
        ->in($driver)
        ->what($class->fields_mapping)
        ->select(sub {
                my %h = map { my $v = $entity->{$_}; s/^${source_path}_//; $_ => $v } keys %$entity;
                if ( my $old = $driver->cache->get($class->get_cache_code($class->id_value_from_hash(\%h))) )
                {
                    return $old;
                }
                my $e = $class->new(%h);
                $driver->cache->set($e->get_cache_code, $e);
                $e->after_load;
                return $e;
            });

    my $list;
    if ( $limit )
    {
        $query->skip($offset || 0);
    }

    if ( $count )
    {
        ($list, $count) = $query->count($limit);
        return ($list, $count);
    }
    else
    {
        $list = [$query->take($limit)];
    }

    return ($list, undef);
}

sub load
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $id = shift;
    my @val = ref $id ? @{$id} : $id;
    return undef unless scalar @val && defined $val[0] && $val[0] ne '';

    my $driver = storage->driver($class->driver_type, $class->source_name);

    assert {$driver} 'Not defined driver';
    return new Ambrosia::core::Nil unless $driver;

    if ( my $old = $driver->cache->get($class->get_cache_code($id)) )
    {
        return $old;
    }

    my $entity;
    my $query = Ambrosia::QL
        ->from([$class->source_path()], \$entity)
        ->in($driver)
        ->what($class->fields_mapping);

    my $key = $class->key;

    foreach ( ref $key ? @$key : ($key) )
    {
        $query->predicate($_, '=', shift(@val));
    }

    my $source_path = join '_', grep defined $_, $class->source_path();

    my @new_e = $query->select(sub {
            my %h = map { my $v = $entity->{$_}; s/^${source_path}_//; $_ => $v } keys %$entity;
            if ( my $old = $driver->cache->get($class->get_cache_code($class->id_value_from_hash(\%h))) )
            {
                return $old;
            }
            my $e = $class->new(%h);
            $driver->cache->set($e->get_cache_code, $e);
            $e->after_load;
            return $e;
        })->take(1);

    return $new_e[0];
}

################################################################################
#Вызывается из save перед формированием запроса к базе.
sub before_save
{
    1;
}

sub after_save
{
    1;
}

sub save
{
    my $self = shift;

    return $self if $self->IS_SAVED;
    return new Ambrosia::core::Nil unless $self->before_save(@_);

    if ( $self->need_insert )
    {
        $self->insert;
    }
    elsif ( $self->need_update )
    {
        $self->update;
    }
    else
    {
        assert {0} 'Unknown state="' . $self->_state . '"';
        return new Ambrosia::core::Nil;
    }

    $self->SET_SAVED;
    $self->after_save(@_);
    return $self;
}

#catalog -- schema(db name) -- table
sub insert
{
    my $self = shift;

    my $driver = storage->driver($self->driver_type, $self->source_name);
    assert {$driver} 'Unknown source for insert data: ' . ($self->source_name || 'undefined source');
    return new Ambrosia::core::Nil unless $driver;

    $driver->reset()
        ->source( $self->source_path() )
        ->insert()
        ->what( $self->fields_mapping() )
        ->execute( $self->value($self->fields) );

    if ( (my $pk = $self->primary_key()) && $self->IS_NEW )
    {
        $self->$pk = $driver->last_insert_id($self->source_path(), $pk);
        $driver->cache->set($self->get_cache_code(), $self);
    }
}

sub delete
{
    my $self = shift;

    my $driver = storage->driver($self->driver_type, $self->source_name);
    assert {$driver} 'Unknown source for delete data: ' . ($self->source_name || 'undefined source');
    return new Ambrosia::core::Nil unless $driver;

    my %cond = @_;
    my $q = $driver->reset()
        ->source( $self->source_path() )
        ->delete();
    foreach ( keys %cond )
    {
        $q->predicate($_, '=', $cond{$_});
    }
    $q->execute(0);
    if ( ref $self )
    {
        $driver->cache->delete($self->get_cache_code());
    }
}

sub update
{
    my $self = shift;

    my $driver = storage->driver($self->driver_type, $self->source_name);
    assert {$driver} 'Unknown source for update data: ' . ($self->source_name || 'undefined source');
    return new Ambrosia::core::Nil unless $driver;

    my $q = $driver->reset()
        ->source( $self->source_path() )
        ->update()
        ->what( $self->fields_mapping() );

    foreach ( pare_list($self->key, $self->key_value) )
    {
        $q->predicate($_->[0], '=', $_->[1]);
    }
    $q->execute($self->value($self->edit_fields));
}

sub find
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $var = shift || my $entity;

    my $driver = storage->driver($class->driver_type, $class->source_name);
    assert {$driver} 'Unknown source for find data: ' . ($class->source_name || 'undefined source');
    return new Ambrosia::core::Nil unless $driver;

    my $source_path = join '_', grep defined $_, $class->source_path();

    return Ambrosia::EntityDataModel::_find->new(
                edm => $class,
                var => \$var,
                query => Ambrosia::QL
                    ->from([$class->source_path()], \$var)
                    ->in($driver)
                    ->what($class->fields_mapping)
                    ->select(sub {
                            my %h = map { my $v = $var->{$_}; s/^${source_path}_//; $_ => $v } keys %$var;
                            %$var = %h;
                            if ( my $old = $driver->cache->get($class->get_cache_code($class->id_value_from_hash(\%h))) )
                            {
                                return $old;
                            }
                            my $e = $class->new(%h);
                            $driver->cache->set($e->get_cache_code, $e);
                            $e->after_load;
                            return $e;
                        })
                );

}

sub link_one2one
{
    no strict 'refs';
    my $proto = shift;
    my %params = @_;
    my $type = $params{type};

    my $pk = $params{from};

    my $yeld = $params{optional}
        ? sub {new Ambrosia::core::Nil}
        : sub {throw Ambrosia::error::Exception shift};

    if ( $type->primary_key && $type->primary_key eq $params{to} )
    {
        *{$proto . '::' . $params{name}} = sub() {
                my $self = shift;

                return ($self->$pk ? $type->load($self->$pk) : undef)
                    || $yeld->('Wrong relationship for ' . $type . ': ' . $pk . '=' . $self->$pk);
            };
    }
    else
    {
        my @key = ref $params{to} ? @{$params{to}} : $params{to};
        my @val = ref $params{from} ? @{$params{from}} : $params{from};
        my $condition = sub {shift(), shift()};
        while( my $k = shift(@key) )
        {
            my $v = shift(@val);
            my $old = $condition;
            $condition = sub { my $self = shift; my $q = shift; $old->($self, $q)->predicate($k, '=', $self->$v); $q; }
        }

        *{$proto . '::' . $params{name}} = sub() {
                my $self = shift;
                return
                    ($condition->($self, $type->find())->take(1))[0]
                    || $yeld->('Wrong relationship: not found entity of ' . $type . ' for ' . $proto . ': '
                               . join(',', @key)
                               . ' [' . join(',', map {$self->$_} (ref $params{from} ? @{$params{from}} : $params{from})) . ']'
                               );
            };
    }
}

sub link_one2many
{
    no strict 'refs';
    my $proto = shift;
    my %params = @_;

    my $yeld = $params{optional}
        ? sub {new Ambrosia::core::Nil}
        : sub {throw Ambrosia::error::Exception shift};

    my @key = ref $params{to} ? @{$params{to}} : $params{to};
    my @val = ref $params{from} ? @{$params{from}} : $params{from};
    my $condition = sub {shift(), shift()};
    while( my $k = shift(@key) )
    {
        my $v = shift(@val);
        my $old = $condition;
        $condition = sub { my $self = shift; my $q = shift; $old->($self, $q)->predicate($k, '=', $self->$v); return $q; }
    }

    *{$proto . '::' . $params{name}} = sub() {
        my $self = shift;
        my @list = $condition->($self, $params{type}->find())->take();
        return scalar @list
            ? \@list
            : $yeld->('Wrong relationship: not found ' . $params{type} . ' for ' . $proto . ': '
                       . join(',', @key)
                       . ' [' . join(',', map {$self->$_} (ref $params{from} ? @{$params{from}} : $params{from})) . ']'
                       );
        };
}

package Ambrosia::EntityDataModel::_find;
use Ambrosia::Meta;
class sealed {
    public => [qw/edm var query/],
};

sub predicate
{
    goto &where;
}

sub where
{
    my $self = shift;
    my @p = @_;
    if ( ref $p[0] eq 'CODE' )
    {
        $self->query->predicate(sub() {
                local $_ = ${$self->var};
                $p[0]->();
            });
    }
    else
    {
        $self->query->predicate(@_);
    }
    return $self;
}

sub uniq
{
    shift->query->uniq(@_);
}

sub skip
{
    shift->query->skip(@_);
}

sub take
{
    shift->query->take(@_);
}

sub count
{
    shift->query->count(@_);
}

sub order_by
{
    shift->query->order_by(@_);
}

1;

__END__

=head1 NAME

Ambrosia::EntityDataModel - ORM.

=head1 VERSION

version 0.010

=head1 SYNOPSIS


=head1 DESCRIPTION

C<Ambrosia::EntityDataModel> .

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 SEE ALSO

L<Ambrosia::QL>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
