package AlignDB::SQL;
use Moose;
use MooseX::Storage;
use YAML qw(Dump Load DumpFile LoadFile);
with Storage( 'format' => 'YAML' );

our $VERSION = '1.0.2';

has 'select'             => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'select_map'         => ( is => 'rw', isa => 'HashRef',  default => sub { {} } );
has 'select_map_reverse' => ( is => 'rw', isa => 'HashRef',  default => sub { {} } );
has 'from'               => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'joins'              => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'where'              => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'bind'               => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'limit'              => ( is => 'rw', isa => 'Int' );
has 'offset'             => ( is => 'rw', );
has 'group'              => ( is => 'rw', );
has 'order'              => ( is => 'rw', );
has 'having'             => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'where_values'       => ( is => 'rw', isa => 'HashRef',  default => sub { {} } );
has '_sql'    => ( is => 'rw', isa => 'Str',     default => '' );
has 'indent'  => ( is => 'rw', isa => 'Str',     default => ' ' x 2 );
has 'replace' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub add_select {
    my $self = shift;
    my ( $term, $col ) = @_;
    $col ||= $term;
    push @{ $self->select }, $term;
    $self->select_map->{$term}        = $col;
    $self->select_map_reverse->{$col} = $term;
}

sub add_join {
    my $self = shift;
    my ( $table, $joins ) = @_;
    push @{ $self->joins },
        {
        table => $table,
        joins => ref($joins) eq 'ARRAY' ? $joins : [$joins],
        };
}

sub as_header {
    my $self = shift;

    my @terms;
    if ( @{ $self->select } ) {
        my %select_map = %{ $self->select_map };
        for my $term ( @{ $self->select } ) {
            if ( exists $select_map{$term} ) {
                my $alias = $select_map{$term};
                push @terms, $alias;
            }
            else {
                push @terms, $term;
            }
        }
    }

    if ( keys %{ $self->replace } ) {
        for my $find ( keys %{ $self->replace } ) {
            my $replace = ${ $self->replace }{$find};
            for (@terms) {
                s/\Q$find\E/$replace/gi;
            }
        }
    }

    return @terms;
}

sub as_sql {
    my $self = shift;

    my $indent = $self->indent;
    my $sql    = '';

    if ( @{ $self->select } ) {
        my %select_map = %{ $self->select_map };
        my @terms;
        for my $term ( @{ $self->select } ) {
            if ( exists $select_map{$term} ) {
                my $alias = $select_map{$term};

                # add_select( 'f.foo'    => 'foo' ) ===> f.foo
                # add_select( 'COUNT(*)' => 'count' ) ===> COUNT(*) count
                if ( $alias and $term =~ /(?:^|\.)\Q$alias\E$/ ) {
                    push @terms, $term;
                }
                else {
                    push @terms, "$term $alias";
                }
            }
            else {
                push @terms, $term;
            }
        }

        $sql .= "SELECT\n";
        $sql .= $indent . join( ",\n$indent", @terms ) . "\n";
    }
    $sql .= "FROM ";

    # Add any explicit JOIN statements before the non-joined tables.
    if ( $self->joins && @{ $self->joins } ) {
        my $initial_table_written = 0;
        for my $j ( @{ $self->joins } ) {
            my ( $table, $joins ) = map { $j->{$_} } qw( table joins );
            $sql .= $table unless $initial_table_written++;
            for my $join ( @{ $j->{joins} } ) {
                $sql
                    .= "\n"
                    . $indent
                    . uc( $join->{type} )
                    . ' JOIN '
                    . $join->{table} . " ON\n"
                    . $indent x 2
                    . $join->{condition};
            }
        }
        $sql .= ', ' if @{ $self->from };
    }
    $sql .= join( ', ', @{ $self->from } ) . "\n";
    $sql .= $self->as_sql_where;

    $sql .= $self->as_aggregate('group');
    $sql .= $self->as_sql_having;
    $sql .= $self->as_aggregate('order');

    $sql .= $self->as_limit;

    if ( keys %{ $self->replace } ) {
        for my $find ( keys %{ $self->replace } ) {
            my $replace = ${ $self->replace }{$find};
            $sql =~ s/\Q$find\E/$replace/gi;
        }
    }

    return $sql;
}

sub as_limit {
    my $self = shift;
    my $n    = $self->limit
        or return '';
    return sprintf "LIMIT %d%s\n", $n, ( $self->offset ? " OFFSET " . int( $self->offset ) : "" );
}

sub as_aggregate {
    my $self   = shift;
    my ($set)  = @_;
    my $indent = $self->indent;

    if ( my $attribute = $self->$set() ) {
        my $elements
            = ( ref($attribute) eq 'ARRAY' ) ? $attribute : [$attribute];
        return
              uc($set)
            . " BY\n$indent"
            . join( ",\n$indent",
            map { $_->{column} . ( $_->{desc} ? ( ' ' . $_->{desc} ) : '' ) } @$elements )
            . "\n";
    }

    return '';
}

sub as_sql_where {
    my $self   = shift;
    my $indent = $self->indent;
    $self->where && @{ $self->where }
        ? 'WHERE ' . join( "\n$indent" . "AND ", @{ $self->where } ) . "\n"
        : '';
}

sub as_sql_having {
    my $self   = shift;
    my $indent = $self->indent;
    $self->having && @{ $self->having }
        ? 'HAVING ' . join( "\n$indent" . "AND ", @{ $self->having } ) . "\n"
        : '';
}

sub add_where {
    my $self = shift;
    ## xxx Need to support old range and transform behaviors.
    my ( $col, $val ) = @_;

    #croak("Invalid/unsafe column name $col") unless $col =~ /^[\w\.]+$/;
    my ( $term, $bind ) = $self->_mk_term( $col, $val );
    push @{ $self->{where} }, "($term)";
    push @{ $self->{bind} },  @$bind;
    $self->where_values->{$col} = $val;
}

sub has_where {
    my $self = shift;
    my ( $col, $val ) = @_;

    # TODO: should check if the value is same with $val?
    exists $self->where_values->{$col};
}

sub add_having {
    my $self = shift;
    my ( $col, $val ) = @_;

    if ( my $orig = $self->select_map_reverse->{$col} ) {
        $col = $orig;
    }

    my ( $term, $bind ) = $self->_mk_term( $col, $val );
    push @{ $self->{having} }, "($term)";
    push @{ $self->{bind} },   @$bind;
}

#@returns AlignDB::SQL
sub copy {
    my $self = shift;
    my $copy = __PACKAGE__->thaw( $self->freeze );
    return $copy;
}

sub _mk_term {
    my $self = shift;
    my ( $col, $val ) = @_;
    my $term = '';
    my @bind;
    if ( ref($val) eq 'ARRAY' ) {
        if ( ref $val->[0] or $val->[0] eq '-and' ) {
            my $logic  = 'OR';
            my @values = @$val;
            if ( $val->[0] eq '-and' ) {
                $logic = 'AND';
                shift @values;
            }

            my @terms;
            for my $v (@values) {
                my ( $term, $bind ) = $self->_mk_term( $col, $v );
                push @terms, "($term)";
                push @bind,  @$bind;
            }
            $term = join " $logic ", @terms;
        }
        else {
            $term = "$col IN (" . join( ',', ('?') x scalar @$val ) . ')';
            @bind = @$val;
        }
    }
    elsif ( ref($val) eq 'HASH' ) {
        my $c = $val->{column} || $col;
        $term = "$c $val->{op} ?";
        push @bind, $val->{value};
    }
    elsif ( ref($val) eq 'SCALAR' ) {
        $term = "$col $$val";
    }
    else {
        $term = "$col = ?";
        push @bind, $val;
    }

    return ( $term, \@bind );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::SQL - An SQL statement generator.

=head1 SYNOPSIS

    my $sql = AlignDB::SQL->new();
    $sql->select([ 'id', 'name', 'bucket_id', 'note_id' ]);
    $sql->from([ 'foo' ]);
    $sql->add_where('name',      'fred');
    $sql->add_where('bucket_id', { op => '!=', value => 47 });
    $sql->add_where('note_id',   \'IS NULL');
    $sql->limit(1);

    my $sth = $dbh->prepare($sql->as_sql);
    $sth->execute(@{ $sql->{bind} });
    my @values = $sth->selectrow_array();

    my $obj = SomeObject->new();
    $obj->set_columns(...);

=head1 DESCRIPTION

I<AlignDB::SQL> represents an SQL statement.

Most codes come from Data::ObjectDriver::SQL

=head1 ATTRIBUTES

=head2 replace

with this, as_sql() method will replace strings in the final SQL statement

=head1 ACKNOWLEDGEMENTS

Sixapart

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
