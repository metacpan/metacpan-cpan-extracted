package DBIx::MoCo::Relation;
use strict;
use Carp;
use UNIVERSAL::require;

my $relation = {};

sub register {
    my $class = shift;
    my ($klass, $type, $attr, $model, $option) = @_;

    $model->require or die $@;
    $model->import;

    $relation->{$klass} ||= {has_a => {},has_many => {}};
    $relation->{$klass}->{$type}->{$attr} = {
        class  => $model,
        option => $option || '',
    };
    my $registry = 'register_' . $type;
    $class->$registry(@_);
    $class->register_flusher(@_);
}

sub register_has_a {
    my $class = shift;
    my ($klass, $type, $attr, $model, $option) = @_;
    my ($my_key, $other_key);
    $option->{key} or return;
    if (ref $option->{key} eq 'HASH') {
        ($my_key, $other_key) = %{$option->{key}};
    } else {
        $my_key = $other_key = $option->{key};
    }
    my $icache_key = $attr;
    my $cs = $klass->cache_status;
    my $subname = $klass . '::' . $attr;
    no strict 'refs';
    no warnings 'redefine';
    if ($klass->icache_expiration) {
        *$subname = sub {
            my $self = shift;
            my $ic = $self->icache;
            if ($ic && defined $ic->{$icache_key}) {
                $cs->{retrieve_count}++;
                $cs->{retrieve_icache_count}++;
                return $ic->{$icache_key};
            } else {
                defined $self->{$my_key} or return;
                my $o = $model->retrieve($other_key => $self->{$my_key}) || undef;
                $ic->{$icache_key} = $o if $o;
                return $o;
            }
        };
    } else {
        *$subname = sub {
            my $self = shift;
            defined $self->{$my_key} or return;
            $model->retrieve($other_key => $self->{$my_key}) || undef;
        };
    }
}

sub register_has_many {
    my $class = shift;
    my ($klass, $type, $attr, $model, $option) = @_;
    # my $array_key = $klass->has_many_keys_name($attr);
    # my $max_key = $klass->has_many_max_offset_name($attr);

    $option->{key} or confess 'key is not specified';

    {
        no strict 'refs';
        no warnings 'redefine';

        *{"$klass\::$attr"}  = sub {
            my $extend = pop if ref $_[-1] and ref $_[-1] eq 'HASH';
            my ($self, $off, $lt) = @_;

            $extend        ||= {};
            $off           ||= 0;
            my $max_off    = defined $lt ? $off + $lt : undef;
            my $icache     = $self->icache;
            my $cache_key  = $self->has_many_keys_cache_name($attr);
            my $icache_key = $attr;
            my $cs         = $klass->cache_status;

            $cs->{has_many_count}++;

            my $cond_cached = sub {
                my ($keys, $max_offset) = @_;
                defined $keys or return;
                defined $keys->{array} or return;

                return (defined $keys->{max_offset} && $keys->{max_offset} == -1)
                    || ($max_off && 0 <= $max_off && $max_off <= $keys->{max_offset});
            };

            my $keys = $self->cache($cache_key);

            if ( $cond_cached->($keys, $max_off) ) {
                # warn "use cache for $cache_key";
                $cs->{has_many_cache_count}++;

                if ($icache && $icache->{$icache_key}) {
                    $cs->{has_many_icache_count}++;
                    # warn "use icache $icache_key for " . $self;
                    return $icache->{$icache_key}->slice( $off, defined $max_off ? $max_off - 1 : undef );
                }

                # warn "$attr cache($keys->{max_offset}) is in range $max_off";
            } else {
                # warn "use db for $cache_key";
                my ($my_key, $other_key);
                ref $option->{key} eq 'HASH'
                    ? ($my_key, $other_key) = %{$option->{key}}
                    : $my_key = $other_key = $option->{key};

                defined $self->{$my_key} or return;

                my $where_clause = "$other_key = ?";
                $where_clause    = join ' AND ', "$other_key = ?", $option->{condition} if $option->{condition};

                $keys = {
                    array => $model->db->search(
                        where => [ $where_clause, $self->{$my_key} ],
                        field => join(',', @{$model->retrieve_keys || $model->primary_keys}),
                        table => $model->table,
                        order => $option ? $option->{order} || '' : '',
                        group => $option ? $option->{group} || '' : '',
                        limit => (defined $max_off && $max_off > 0) ? $max_off : '',
                    ),
                    max_offset => $max_off || -1,
                };

                $self->cache($cache_key, $keys);
                # warn @{$self->{$array_key}};
            }

            my $last = ($max_off && $max_off <= $#{$keys->{array}}) ? $max_off - 1 : $#{$keys->{array}};

            my $res;
            if ($icache) {
                # warn "set icache and return";
                $icache->{$icache_key} = $model->retrieve_multi(@{$keys->{array}});
                $res = $icache->{$icache_key}->slice($off, $last);
            } else {
                $res = $model->retrieve_multi(@{$keys->{array}}[$off || 0 .. $last]);
            }

            my $with = $extend->{with} || $class->find_relation_by_attr($klass => $attr)->{option}->{with};
            my $without = $extend->{without};

            if ($with and $res->size > 0) {
                $model->merge_with($res, $with, $without);
            }

            wantarray ? @$res : $res;
        };
    }
}

sub register_flusher {
    shift; # Relation
    my ($klass, $type, $attr, $model, $option) = @_;
    my $flusher = $klass . '::flush_belongs_to';
    no strict 'refs';
    no warnings 'redefine';
    *$flusher = sub {
        # warn "level 1 flusher called for $flusher";
        my ($class, $self) = @_;
        $self or confess '$self is not specified';
        my $has_a = $relation->{$klass}->{has_a};
        for my $attr (keys %$has_a) {
            my $ha = $has_a->{$attr};
            my $oa = [];
            my $other = $relation->{$ha->{class}};
            for my $oattr (keys %{$other->{has_many}}) {
                my $hm = $other->{has_many}->{$oattr};
                if ($hm->{class} eq $class) {
                    # push @$oa, $ha->{class}->has_many_keys_name($oattr);
                    push @$oa, $oattr;
                }
            }
            $ha->{other_attrs} = $oa;
            # warn join(' / ', %$ha);
        }
        *$flusher = sub {
            # warn "level 2 flusher called for $flusher";
            my ($class, $self) = @_;
            for my $attr (keys %$has_a) {
                my $parent = $self->$attr() or next;
                for my $oattr (@{$has_a->{$attr}->{other_attrs}}) {
                    # warn "call $self->$attr->flush($oattr)";
                    $parent->flush_has_many_keys($oattr);
                    $parent->flush_icache($oattr);
                }
            }
        };
        goto &$flusher;
    };
}

sub find_relation_by_attr {
    my ($class, $klass, $attr) = @_;
    $relation->{$klass} or return;

    if (my $has_a = $relation->{$klass}->{has_a}->{$attr}) {
        return $has_a;
    }

    if (my $has_many = $relation->{$klass}->{has_many}->{$attr}) {
        return $has_many;
    }

    return;
}

1;

__END__

=head1 NAME

DBIx::MoCo::Relation - Storage class for relation definitions.

=head1 SEE ALSO

L<DBIx::MoCo>

=head1 AUTHOR

Junya Kondo, E<lt>http://jkondo.vox.com/E<gt>,
Naoya Ito, E<lt>naoya@hatena.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

