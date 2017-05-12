package DBIx::Class::ResultSet::Void;
our $VERSION = '0.06';

# ABSTRACT: improve DBIx::Class::ResultSet with void context

use strict;
use warnings;
use Carp::Clan qw/^DBIx::Class/;

use base qw(DBIx::Class::ResultSet);

sub exists {
    my ( $self, $query ) = @_;

    return $self->search( $query, { rows => 1, select => [1] } )->single;
}

sub find_or_create {
    my $self = shift;

    return $self->next::method(@_) if ( defined wantarray );

    my $attrs = ( @_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {} );
    my $hash = ref $_[0] eq 'HASH' ? shift : {@_};

    my $query = $self->___get_primary_or_unique_key( $hash, $attrs );
    my $exists = $self->exists($query);
    $self->create($hash) unless $exists;
}

sub update_or_create {
    my $self = shift;

    return $self->next::method(@_) if ( defined wantarray );

    my $attrs = ( @_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {} );
    my $cond = ref $_[0] eq 'HASH' ? shift : {@_};

    my $query = $self->___get_primary_or_unique_key( $cond, $attrs );
    my $exists = $self->exists($query);

    if ($exists) {

        # dirty hack, to remove WHERE cols from SET
        my $query_array = ref $query eq 'ARRAY' ? $query : [$query];
        foreach my $_query (@$query_array) {
            foreach my $_key ( keys %$_query ) {
                delete $cond->{$_key};
                delete $cond->{$1} if $_key =~ /\w+\.(\w+)/;    # $alias.$col
            }
        }
        $self->search($query)->update($cond) if keys %$cond;
    }
    else {
        $self->create($cond);
    }
}

# mostly copied from sub find
sub ___get_primary_or_unique_key {
    my $self = shift;
    my $attrs = ( @_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {} );

    # Default to the primary key, but allow a specific key
    my @cols =
      exists $attrs->{key}
      ? $self->result_source->unique_constraint_columns( $attrs->{key} )
      : $self->result_source->primary_columns;
    $self->throw_exception(
"Can't find unless a primary key is defined or unique constraint is specified"
    ) unless @cols;

    # Parse out a hashref from input
    my $input_query;
    if ( ref $_[0] eq 'HASH' ) {
        $input_query = { %{ $_[0] } };
    }
    elsif ( @_ == @cols ) {
        $input_query = {};
        @{$input_query}{@cols} = @_;
    }
    else {

        # Compatibility: Allow e.g. find(id => $value)
        carp "Find by key => value deprecated; please use a hashref instead";
        $input_query = {@_};
    }

    my ( %related, $info );

  KEY: foreach my $key ( keys %$input_query ) {
        if ( ref( $input_query->{$key} )
            && ( $info = $self->result_source->relationship_info($key) ) )
        {
            my $val = delete $input_query->{$key};
            next KEY if ( ref($val) eq 'ARRAY' );    # has_many for multi_create
            my $rel_q =
              $self->result_source->resolve_condition( $info->{cond}, $val,
                $key );
            die "Can't handle OR join condition in find"
              if ref($rel_q) eq 'ARRAY';
            @related{ keys %$rel_q } = values %$rel_q;
        }
    }
    if ( my @keys = keys %related ) {
        @{$input_query}{@keys} = values %related;
    }

    # Build the final query: Default to the disjunction of the unique queries,
    # but allow the input query in case the ResultSet defines the query or the
    # user is abusing find
    my $alias =
      exists $attrs->{alias} ? $attrs->{alias} : $self->{attrs}{alias};
    my $query;
    if ( exists $attrs->{key} ) {
        my @unique_cols =
          $self->result_source->unique_constraint_columns( $attrs->{key} );
        my $unique_query =
          $self->_build_unique_query( $input_query, \@unique_cols );
        $query = $self->_add_alias( $unique_query, $alias );
    }
    else {
        my @unique_queries = $self->_unique_queries( $input_query, $attrs );
        $query =
          @unique_queries
          ? [ map { $self->_add_alias( $_, $alias ) } @unique_queries ]
          : $self->_add_alias( $input_query, $alias );
    }

    return $query;
}

1;
__END__

=head1 NAME

DBIx::Class::ResultSet::Void - improve DBIx::Class::ResultSet with void context

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $rs = $schema->resultset('CD');
    $rs->find_or_create( {
        artist => 'Massive Attack',
        title  => 'Mezzanine',
    } );

As ResultSet subclass in Schema.pm:

    __PACKAGE__->load_namespaces(
        default_resultset_class => '+DBIx::Class::ResultSet::Void'
    );

Or in Schema/CD.pm

    __PACKAGE__->resultset_class('DBIx::Class::ResultSet::Void');

Or in ResultSet/CD.pm

    use base 'DBIx::Class::ResultSet::Void';

=head1 DESCRIPTION

The API is the same as L<DBIx::Class::ResultSet>.

use C<exists> instead of C<find> unless defined wantarray.

(Thank ribasushi to tell me C<count> is bad)

=head2 METHODS

=over 4

=item * exists

    $rs->exists( { id => 1 } );

It works like:

    $rs->search( { id => 1 }, { rows => 1, select => [1] } )->single;

It is a little faster than C<count> if you don't care the real count.

=item * find_or_create

L<DBIx::Class::ResultSet/find_or_create>:

    $rs->find_or_create( { id => 1, name => 'A' } );

produces SQLs like:

    # SELECT me.id, me.name FROM item me WHERE ( me.id = ? ): '1'
    # INSERT INTO item ( id, name) VALUES ( ?, ? ): '1', 'A'

but indeed C<SELECT 1 ...  LIMIT 1> is performing a little better than me.id, me.name

this module L<DBIx::Class::ResultSet::Void> produces SQLs like:

    # SELECT 1 FROM item me WHERE ( me.id = ? ) LIMIT 1: '1'
    # INSERT INTO item ( id, name) VALUES ( ?, ? ): '1', 'A'

we would delegate it DBIx::Class::ResultSet under context like:

    my $row = $rs->find_or_create( { id => 1, name => 'A' } );

=item * update_or_create

L<DBIx::Class::ResultSet/update_or_create>:

    $rs->update_or_create( { id => 1, name => 'B' } );

produces SQLs like:

    # SELECT me.id, me.name FROM item me WHERE ( me.id = ? ): '1'
    # UPDATE item SET name = ? WHERE ( id = ? ): 'B', '1'

this module:

    # SELECT 1 FROM item me WHERE ( me.id = ? ) LIMIT 1: '1'
    # UPDATE item SET name = ? WHERE ( id = ? ): 'B', '1'

=back

=head1 AUTHOR

  Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=pod 
