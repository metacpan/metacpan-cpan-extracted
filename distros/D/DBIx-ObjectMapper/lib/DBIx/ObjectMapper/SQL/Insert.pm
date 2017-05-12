package DBIx::ObjectMapper::SQL::Insert;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Scalar::Util qw(blessed);
use base qw(DBIx::ObjectMapper::SQL::Base);

__PACKAGE__->initdata({
    into   => undef,
    values => {},
});

__PACKAGE__->accessors({
    convert_table_to_sql => [qw(into)],
});

sub values {
    my $self = shift;
    if( @_ ) {
        if ( ref $_[0] eq 'ARRAY' ) {
            $self->{values} = \@_;
        }
        elsif( ref $_[0] eq 'HASH' and @_ > 1 ) {
            my @values = $self->_convert_insert_values_hash_to_array(@_);
            $self->{values} = \@values;
        }
        elsif( @_ > 1 and @_ % 2 == 0 ) {
            $self->{values} = {@_};
        }
        elsif( @_ == 1 and ref $_[0] eq 'HASH' ) {
            $self->{values} = $_[0];
        }
        else {
            confess "Invalid Argument";
        }

        return $self;
    }

    return $self->{values};
}

sub _convert_insert_values_hash_to_array {
    my $self = shift;
    my @keys = sort keys %{$_[0]};
    my @values = ( \@keys );
    for my $hash ( @_ ) {
        my @val = map{ $hash->{$_} } @keys;
        push @values, \@val;
    }
    return @values;
}

sub add_values {
    my $self = shift;

    if ( ref $_[0] eq 'ARRAY' ) {
        $self->{values} = [] unless ref $self->{values} eq 'ARRAY';
        push @{$self->{values}}, @_;
    }
    elsif( ref $_[0] eq 'HASH' and @_ > 1 ) {
        my @values = $self->_convert_insert_values_hash_to_array(@_);
        $self->add_values(\@values);
    }
    elsif ( @_ > 1 and @_ % 2 == 0 ) {
        my %values = @_;
        $self->{values}{$_} = $values{$_} for keys %values;
    }
    elsif( @_ == 1 and ref $_[0] eq 'HASH' ) {
        $self->add_values(%{$_[0]});
    }
    else {
        confess "Invalid Argument";
    }

    $self;
}

sub _values_as_sql {
    my $self = shift;
    my $values = shift;

    if ( ref $values eq 'HASH' ) {
        my ( @col, @val, @bind );

        for my $key ( sort keys %$values ) {
            push @col, $key;
            if( ref $values->{$key} eq 'SCALAR' ) {
                push @val, ${$values->{$key}};
            }
            elsif( ref $values->{$key} eq 'REF' ) {
                my $val = ${$values->{$key}};
                push @val, '?';
                push @bind, $val;
            }
            else {
                push @val, '?';
                push @bind, $values->{$key};
            }
        }

        return sprintf(
            " ( %s ) VALUES (%s)",
            join( ', ', @col ),
            join( ',', @val )
        ), @bind;
    }
    elsif ( ref $values eq 'ARRAY' ) {
        if ( ref $values->[1] eq 'ARRAY' ) {
            my $col = shift(@$values);
            my $stm = sprintf(" ( %s ) VALUES ", join( ', ', @$col) );
            my @multi_stm;
            my @bind_val;
            for my $v ( @$values ) {
                my ( @val, @bind );
                for my $vv ( @$v ) {
                    if( ref $vv eq 'SCALAR' ) {
                        push @val, $$vv;
                    }
                    elsif( ref $vv eq 'REF' ) {
                        my $val = $$vv;
                        push @val, '?';
                        push @bind, $val;
                    }
                    else {
                        push @val, '?';
                        push @bind, $vv;
                    }
                }

                push @multi_stm, sprintf( "(%s)", join( ',', @val ) );
                push @bind_val, @bind;
            }
            $stm .= join(', ', @multi_stm );
            return $stm, @bind_val;
        }
        elsif( blessed $values->[1] and $values->[1]->can('as_sql') ) {
            my ( $stm, @bind ) = $values->[1]->as_sql;
            return sprintf( " ( %s ) %s",
                join( ', ', @{ $values->[0] } ), $stm ),
                @bind;
        }
    }
    else {
        return;
    }
}

sub as_sql {
    my $self = shift;
    my ($stm, @bind);

    my ( $table_name, @no_bind ) = $self->into_as_sql;
    $stm = 'INSERT INTO ' . $table_name;

    my ($value_stm, @value_bind) = $self->_values_as_sql($self->{values});
    $stm .= $value_stm;
    push @bind, @value_bind if @value_bind;

    return ( $stm, @bind );
}

1;
