package DBIx::ObjectMapper::SQL::Update;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::SQL::Base);

__PACKAGE__->initdata({
    table => undef,
    set   => {},
    where => [],
});

__PACKAGE__->accessors({
    convert_table_to_sql => [qw(table)],
    build_where          => [qw(where)],
});

sub set {
    my $self = shift;
    if( @_ and @_ % 2 == 0 ) {
        $self->{set} = {@_};
        return $self;
    }
    else {
        return $self->{set};
    }
}

sub add_set {
    my $self = shift;
    if( @_ % 2 == 0 ) {
        my %set = @_;
        for my $key ( keys %set ) {
            $self->{set}{$key} = $set{$key};
        }
    }
}

sub set_as_sql {
    my $self = shift;

    my @key;
    my @bind;
    for my $key ( keys %{$self->{set}} ) {
        if( ref $self->{set}{$key} eq 'SCALAR' ) {
            push @key, $key . ' = ' . ${$self->{set}{$key}};
        }
        else {
            push @key, $key . ' = ?';
            push @bind, $self->{set}{$key};
        }
    }
    return join( ' , ', @key ), @bind;
}

sub as_sql {
    my $self = shift;

    my ( $stm, @bind );

    my ( $table_name, @no_bind ) = $self->table_as_sql;
    $stm .= 'UPDATE ' . $table_name;

    my ( $set_stm, @set_bind ) = $self->set_as_sql;
    $stm .= ' SET ' . $set_stm;
    push @bind, @set_bind if @set_bind;

    my ( $where_stm, @where_bind ) = $self->where_as_sql;
    $stm .= ' WHERE ' . $where_stm if $where_stm;
    push @bind, @where_bind if @where_bind;

    return $stm, @bind;
}

1;
