package DBIx::QuickORM::Role::Linked;
use strict;
use warnings;

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

use constant 'LINKS'          => '__links__';
use constant 'BUILT'          => 'built';
use constant 'CACHE_ID'       => 'cache_id';
use constant 'BY_ALIAS'       => 'by_alias';
use constant 'BY_TABLE'       => 'by_table';
use constant 'BY_TABLE_ALIAS' => 'by_table_alias';
use constant 'BY_TABLE_KEY'   => 'by_table_key';

use Role::Tiny;

requires qw{
    links
};

sub connection {}
sub from {}

sub resolve_link {
    my $self = shift;

    my %params;
    if (@_ % 2) {
        my $spec = shift;
        %params = @_;
        $params{spec} = $spec;
    }
    else {
        %params = @_;
    }

    return $params{link} if $params{link};

    my $spec = $params{spec};
    return $spec if $spec && blessed($spec) && $spec->isa('DBIx::QuickORM::Link');

    if ($params{from}) {
        my $s = $self->from($params{from});
        return $s->resolve_link($spec, %params) if $s;
    }

    return DBIx::QuickORM::Link->parse(
        source => $self,
        link        => $spec,
        connection  => $params{connection} // $self->connection,
    ) if ref $spec;

    my $found = $self->_link_from_name(%params) or croak "Could not resolve link";

    return $found unless ref($found) eq 'ARRAY';
    return $found->[0] if @$found == 1;

    croak join "\n" => (
        "Ambiguous link specification, found the following:",
        (map { "local_table: $_->{local_table} | other_table: $_->{other_table} | key: $_->{key} | aliases: " . join(', ', @{$_->{aliases}}) } @$found),
        '',
    );
}

sub _link_from_name {
    my $self = shift;
    my (%params) = @_;

    my $cache = $self->{+LINKS};
    $cache = $self->{+LINKS} = {CACHE_ID() => "$self"} unless $cache && $cache->{+CACHE_ID} eq "$self";

    unless ($cache->{+BUILT}) {
        my %lookup;
        for my $l (sort { $a->other_table cmp $b->other_table || $a->key cmp $b->key } @{$self->links}) {
            my $f = $lookup{$l->other_table}->{$l->key};
            $lookup{$l->other_table}->{$l->key} = $f ? $f->merge($l) : $l;
        }

        $cache->{+BY_TABLE_KEY} = \%lookup;

        for my $link (map {values %{$_}} values %lookup) {
            push @{$cache->{+BY_TABLE}->{$link->other_table}} => $link;

            for my $alias (@{$link->aliases}) {
                push @{$cache->{+BY_ALIAS}->{$alias}} => $link;
                $cache->{+BY_TABLE_ALIAS}->{$link->other_table}->{$alias} //= $link;
            }
        }

        $cache->{+BUILT} = 1;
    }

    my $spec    = $params{spec};
    my $table   = $params{table};
    my $alias   = $params{alias};
    my $columns = $params{columns};
    my $key     = $params{key} //= $columns ? column_key(@$columns) : undef;

    my $out;
    $out //= $cache->{+BY_TABLE_ALIAS}->{$table}->{$alias} if $table && $alias;
    $out //= $cache->{+BY_TABLE_ALIAS}->{$table}->{$spec}  if $table && $spec && !$alias;
    $out //= $cache->{+BY_TABLE_ALIAS}->{$spec}->{$alias}  if $spec  && $alias && !$table;

    $out //= $cache->{+BY_TABLE_KEY}->{$table}->{$key} if $table && $key;
    $out //= $cache->{+BY_TABLE_KEY}->{$spec}->{$key} if $key && $spec && !$table;
    $out //= $cache->{+BY_TABLE_KEY}->{$table}->{$spec} if $table && $spec && !$key;

    $out //= $cache->{+BY_ALIAS}->{$alias} if $alias;
    $out //= $cache->{+BY_ALIAS}->{$spec} if $spec && !$alias;

    $out //= $cache->{+BY_TABLE}->{$table} if $table;
    $out //= $cache->{+BY_TABLE}->{$spec}  if $spec && !$table;

    return $out;
}

1;


__END__

        $found //= $source->links_by_alias->{$link} if $source->can('links_by_alias');

        if ($source->can('links_by_table')) {
            if (my $set = $source->links_by_table->{$link}) {
                my $count = keys %$set;
                croak "Could not find any links to table '$link'" unless $count;
                if ($count > 1) {
                    use Data::Dumper;
                    croak "Found $count links to table '$link', you need to be more specific: " . Dumper($set);
                }
                ($found) = values %$set;
            }
        }

sub _links { delete $_[0]->{+_LINKS} }

sub links_by_table { $_[0]->{+LINKS} }

sub links {
    my $self = shift;
    my ($table) = @_;

    my @tables = $table ? ($table) : keys %{ $self->{+LINKS} };

    return map { values %{ $self->{+LINKS}->{$_} // {}} } @tables;
}

sub link {
    my $self = shift;
    my %params = @_;

    if (my $table = $params{table}) {
        my $links = $self->{+LINKS}->{$table} or return undef;

        if (my $cols = $params{columns} // $params{cols}) {
            my $key = column_key(@$cols);
            return $links->{$key} // undef;
        }

        for my $key (sort keys %$links) {
            return $links->{$key} // undef;
        }

        return undef;
    }
    elsif (my $alias = $params{name}) {
        return $self->{+LINKS_BY_ALIAS}->{$alias} // undef;
    }

    croak "Need a link name or table";
}

sub parse_link {
    my $self = shift;
    my ($link) = @_;

    return $link if blessed($link) && $link->isa('DBIx::QuickORM::Link');

    my $ref = ref($link);

    return $self->source->links_by_alias->{$link} // croak "'$link' is not a valid link alias for table '" . $self->source->name . "'"
        unless $ref;

    return DBIx::QuickORM::Link->parse(
        source => $self->source,
        connection  => $self->connection,
        link        => $link,
    );
}

# TODO move this to a role, ::Row uses it too.
sub _parse_link {
    my $self = shift;
    my ($link, %params) = @_;

    return $link if blessed($link) && $link->isa('DBIx::QuickORM::Link');

    my $ref = ref($link);
    my $found;

    unless ($ref) {
        my $source = $self->{+SOURCE};
        $source = $self->{+SOURCE}->from($params{from}) if $params{from} && $source->can('from');

        $found //= $source->links_by_alias->{$link} if $source->can('links_by_alias');

        if ($source->can('links_by_table')) {
            if (my $set = $source->links_by_table->{$link}) {
                my $count = keys %$set;
                croak "Could not find any links to table '$link'" unless $count;
                if ($count > 1) {
                    use Data::Dumper;
                    croak "Found $count links to table '$link', you need to be more specific: " . Dumper($set);
                }
                ($found) = values %$set;
            }
        }

        croak "Could not resolve link '$link'" unless $found;
    }

    return DBIx::QuickORM::Link->parse(
        source => $self->{+SOURCE},
        connection  => $self->{+CONNECTION},
        link        => $found // $link,
    );
}


