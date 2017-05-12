package CatalystX::CRUD::ModelAdapter::DBIC;
use warnings;
use strict;
use base qw(
    CatalystX::CRUD::ModelAdapter
    CatalystX::CRUD::Model::Utils
);
use MRO::Compat;
use mro 'c3';
use Scalar::Util qw( weaken );
use Carp;
use Data::Dump qw( dump );
use Sort::SQL;

__PACKAGE__->mk_ro_accessors(qw( treat_like_int ));

our $VERSION = '0.15';

=head1 NAME

CatalystX::CRUD::ModelAdapter::DBIC - CRUD for Catalyst::Model::DBIC::Schema

=head1 SYNOPSIS

 # create an adapter class (NOTE not in ::Model namespace)
 package MyApp::MyDBICAdapter;
 use strict;
 use base qw( CatalystX::CRUD::ModelAdapter::DBIC );
 
 1;
 
 # your main DBIC::Schema model
 package MyApp::Model::MyDBIC;
 use strict;
 use base qw( Catalyst::Model::DBIC::Schema );
 
 1;
 
=head1 DESCRIPTION

CatalystX::CRUD::ModelAdapter::DBIC implements the CatalystX::CRUD::ModelAdapter
API for DBIx::Class.

=head1 METHODS

=head2 new( I<opts> )

Overrides base method to initialize treats_like_int, ne_sign and 
use_ilike values.

=cut

# TODO others?
my %is_iliker = (
    Pg         => 1,
    PostgreSQL => 1,
);

sub new {
    my $self = shift->next::method(@_);

    # what kind of db driver are we using.
    # makes a difference in make_sql_query().
    my $db_type
        = $self->app_class->model( $self->model_name )->storage->sqlt_type;

    #warn "DBIC driver: " . $db_type;

    $self->use_ilike( exists $is_iliker{$db_type} );

    # SQL for not equal
    $self->ne_sign('!=');

    # cache the treat_like_int hash
    $self->_treat_like_int;

    #warn dump $self;

    return $self;
}

sub _treat_like_int {
    my $self     = shift;
    my $treat    = {};
    my $moniker  = $self->_get_moniker;
    my $rs_class = $self->app_class->model( $self->model_name )
        ->composed_schema->class($moniker);
    for my $col ( $rs_class->columns ) {
        my $info = $rs_class->column_info($col);

        #warn "$col : " . dump($info);

        if ( keys %$info ) {
            if (    $info->{data_type}
                and $info->{data_type} =~ m/(boolean|date|int)/ )
            {
                $treat->{$col} = 1;
            }
        }

    }

    $self->{treat_like_int} = $treat;
}

=head2 new_object( I<controller>, I<context>, I<moniker> )

Implement required method. Returns empty new_result() object
from resultset() of I<moniker>.

=cut

sub new_object {
    my $self       = shift;
    my $controller = shift;
    my $c          = shift;
    my $moniker    = $self->_get_moniker($c);
    return $c->model( $self->model_name )->resultset($moniker)
        ->new_result( {} );
}

=head2 fetch( I<controller>, I<context>, I<moniker> [, I<args>] )

Implements required method. Returns new_object() matching I<args>.
I<args> is passed to the find() method of the resultset() for I<moniker>.
If I<args> is not passed, fetch() acts the same as calling new_object().

=cut

sub fetch {
    my $self       = shift;
    my $controller = shift;
    my $c          = shift;
    my $moniker    = $self->_get_moniker($c);
    if (@_) {
        my $dbic_obj;
        eval {
            $dbic_obj
                = $c->model( $self->model_name )->resultset($moniker)
                ->find( {@_} );
        };
        if ( $@ or !$dbic_obj ) {
            my $err = defined($dbic_obj) ? $dbic_obj->error : $@;
            return
                if $self->throw_error(
                "can't create new $moniker object: $err");
        }

        return $dbic_obj;
    }
    else {
        return $self->new_object( $controller, $c );
    }
}

=head2 search( I<controller>, I<context>, I<args> )

Implements required method. Returns array or array ref, based
on calling context, for a search() in resultset() for I<args>.

=cut

sub search {
    my ( $self, $controller, $c, @arg ) = @_;
    my $query = shift(@arg) || $self->make_query( $controller, $c );
    my @rs
        = $c->model( $self->model_name )
        ->resultset( $self->_get_moniker($c) )
        ->search( $query->{WHERE}, $query->{OPTS} );
    return wantarray ? @rs : \@rs;
}

sub _get_moniker {
    my ( $self, $c ) = @_;
    my $moniker;
    if ( defined $c ) {
        $moniker = $c->stash->{dbic_schema}
            || $self->model_meta->{dbic_schema};
    }
    else {
        $moniker = $self->model_meta->{dbic_schema};
    }
    unless ($moniker) {
        $self->throw_error(
            "must define a dbic_schema in model_meta config for each CRUD controller"
        );
    }
    return $moniker;
}

=head2 iterator( I<controller>, I<context>, I<args> )

Implements required method. Returns iterator
for a search() in resultset() for I<args>.

=cut

sub iterator {
    my ( $self, $controller, $c, @arg ) = @_;
    my $query = shift(@arg) || $self->make_query( $controller, $c );
    my $rs
        = $c->model( $self->model_name )
        ->resultset( $self->_get_moniker($c) )
        ->search( $query->{WHERE}, $query->{OPTS} );
    return $rs;
}

=head2 count( I<controller>, I<context>, I<args> )

Implements required method. Returns count() in resultset() for I<args>.

=cut

sub count {
    my ( $self, $controller, $c, @arg ) = @_;
    my $query = shift(@arg) || $self->make_query( $controller, $c );
    return $c->model( $self->model_name )
        ->resultset( $self->_get_moniker($c) )
        ->count( $query->{WHERE}, $query->{OPTS} );
}

=head2 make_query( I<controller>, I<context> [, I<field_names> ] )

Returns an array ref of query data based on request params in I<context>,
using param names that match I<field_names>.

=cut

sub make_query {
    my $self       = shift;
    my $controller = shift;
    my $c          = shift;
    my $field_names
        = shift
        || $c->req->params->{'cxc-query-fields'}
        || $self->_get_field_names( $controller, $c );

    my $query = $self->make_sql_query( $controller, $c, $field_names ) || {};

    # WHERE
    $query->{WHERE} = { @{ $query->{query} } };

    my %opts;

    # PREFETCH, etc.
    if ( $controller->model_meta->{resultset_opts} ) {
        %opts = %{ $controller->model_meta->{resultset_opts} };
    }

    # ORDER BY
    #dump $field_names;
    if ( exists $query->{sort_by} ) {
        $opts{order_by} ||= $query->{sort_by};

        # default is to sort by PK, which might not be prefixed.
        my $ss = Sort::SQL->parse( $opts{order_by} );

        #dump $ss;
        my @order_by;
        for my $clause (@$ss) {
            if ( $clause->[0] !~ m/\./ ) {

                if ( $c->req->params->{'cxc-m2m'} ) {

                    # TODO m2m

                }
                else {

                    # o2m
                    my $name = "me." . $clause->[0];
                    if ( grep { $_ eq $name } @$field_names ) {
                        $clause->[0] = $name;
                    }
                }
            }
            push @order_by, { '-' . lc( $clause->[1] ) => $clause->[0] };
        }
        $opts{order_by} = \@order_by;
    }

    #dump \%opts;
    $query->{OPTS} = \%opts;

    $c->log->debug( "query: " . dump $query ) if $c->debug;

    return $query;
}

=head2 make_sql_query( I<controller>, I<context>, I<field_names> )

Override method in CatalystX::CRUD::Model::Utils to mimic
ACCEPT_CONTEXT by setting I<context> in $self. 

Otherwise, acts just like CatalystX::CRUD::Model::Utils->make_sql_query().

=cut

sub make_sql_query {
    my $self        = shift;
    my $controller  = shift;
    my $c           = shift;
    my $field_names = shift;

    # Model::Utils (make_sql_query) assumes ACCEPT_CONTEXT accessor
    $self->{context} = $c;
    weaken( $self->{context} );

    my $q = $self->next::method($field_names);

    #carp "make_sql_query : " . dump $q;

    if ( $q->{query_obj} ) {
        $q->{query} = $q->{query_obj}->dbic;
    }

    #carp "make_sql_query : " . dump $q;

    return $q;
}

=head2 search_related( I<controller>, I<context>, I<obj>, I<relationship> [, I<query> ] )

Implements required method. Returns array ref of
objects related to I<obj> via I<relationship>. I<relationship>
should be a method name callable on I<obj>.

=head2 iterator_related( I<controller>, I<context>, I<obj>, I<relationship> [, I<query> ] )

Like search_related() but returns an iterator.

=head2 count_related( I<controller>, I<context>, I<obj>, I<relationship> [, I<query> ] )

Like search_related() but returns an integer.

=cut

sub search_related {
    my ( $self, $controller, $c, $obj, $rel, $query ) = @_;
    $query ||= $self->make_query( $controller, $c );
    return [ $obj->$rel->search( $query->{WHERE}, $query->{OPTS} ) ];
}

sub iterator_related {
    my ( $self, $controller, $c, $obj, $rel, $query ) = @_;
    $query ||= $self->make_query( $controller, $c );
    return scalar $obj->$rel->search( $query->{WHERE}, $query->{OPTS} );
}

sub count_related {
    my ( $self, $controller, $c, $obj, $rel, $query ) = @_;
    $query ||= $self->make_query( $controller, $c );
    return $obj->$rel->count( $query->{WHERE}, $query->{OPTS} );
}

=head2 add_related( I<controller>, I<context>, I<obj>, I<rel_name>, I<foreign_value> )

Implements optional method as defined by core API. I<rel_name>
should be a method name callable by I<obj>.

=cut

sub add_related {
    my ( $self, $controller, $c, $obj, $rel, $for_val ) = @_;
    my $rinfo = $self->_get_rel_meta( $controller, $c, $obj, $rel );

    #carp "add_related: " . dump $rinfo;

    if ( exists $rinfo->{m2m} ) {
        my $for_obj
            = $self->_get_m2m_foreign_object( $controller, $c, $obj, $rel,
            $rinfo, $for_val );
        my $add_method = 'add_to_' . $rinfo->{m2m}->{method_name};
        $obj->$add_method($for_obj);
    }
    else {
        croak "TODO o2m";
    }
}

sub _get_m2m_foreign_object {
    my ( $self, $controller, $c, $obj, $rel, $rinfo, $for_val ) = @_;
    if ( !exists $rinfo->{m2m} ) {
        $self->throw_error("relationship $rel is not a many-to-many");
    }

    #carp "get foreign object $for_val for $rel : " . dump $rinfo;

    my $m2m           = $rinfo->{m2m};
    my $foreign_class = $m2m->{foreign_class};
    my $fpk           = $m2m->{foreign_column};
    my $for_obj
        = $c->model( $self->model_name )->resultset($foreign_class)
        ->find( { $fpk => $for_val } )
        or $self->throw_error(
        "can't find foreign object in $foreign_class for $for_val");

    return $for_obj;
}

=head2 rm_related( I<controller>, I<context>, I<obj>, I<rel_name>, I<foreign_value> )

Implements optional method as defined by core API. I<rel_name>
should be a method name callable by I<obj>.

=cut

sub rm_related {
    my ( $self, $controller, $c, $obj, $rel, $for_val ) = @_;
    my $rinfo = $self->_get_rel_meta( $controller, $c, $obj, $rel );

    #carp dump $rinfo;
    if ( exists $rinfo->{m2m} ) {

        # isa m2m
        # must find the foreign object to pass to remove_from_$rel()
        my $for_obj
            = $self->_get_m2m_foreign_object( $controller, $c, $obj, $rel,
            $rinfo, $for_val );
        my $rm_method = 'remove_from_' . $rinfo->{m2m}->{method_name};
        $obj->$rm_method($for_obj);

    }
    else {
        croak "TODO o2m";
    }

}

=head2 has_relationship( I<controller>, I<context>, I<obj>, I<rel_name> )

Implements optional method as defined by core API. I<rel_name>
should be a method name callable by I<obj>.

=cut

sub has_relationship {
    my ( $self, $controller, $c, $obj, $rel ) = @_;
    eval { $obj->ensure_class_loaded('DBIx::Class::RDBOHelpers'); };
    if ($@) {
        $self->throw_error("DBIx::Class::RDBOHelpers not loaded for $obj");
    }

    for ( $obj->relationships ) {
        return $obj->relationship_info($_)
            if $_ eq $rel;

        # m2m relationships are not keyed by their method name
        my $info = $obj->relationship_info($_);
        if ( exists $info->{m2m} and $info->{m2m}->{method_name} eq $rel ) {
            return $info;
        }
    }
    return;
}

sub _get_rel_meta {
    my ( $self, $controller, $c, $obj, $rel ) = @_;
    if ( !$self->has_relationship( $controller, $c, $obj, $rel ) ) {
        $self->throw_error("no such relationship $rel defined for $obj");
    }
    return $self->has_relationship( $controller, $c, $obj, $rel )
        || $obj->relationship_info($rel);
}

sub _get_field_names {
    my $self       = shift;
    my $controller = shift;
    my $c          = shift;

    my $moniker = $self->_get_moniker($c);
    return $self->{_field_names}
        if exists $self->{_field_names};

    my $table_obj
        = $c->model( $self->model_name )->composed_schema->class($moniker);
    my @cols = $table_obj->columns;
    my @rels = $table_obj->relationships;

    my @fields;
    for my $rel (@rels) {
        my $info = $self->_get_rel_meta( $controller, $c, $table_obj, $rel );
        my ( $rel_class, $prefix );

        #warn "rel info for $moniker $rel: " . dump $info;
        if ( exists $info->{m2m} ) {
            $rel_class = $info->{m2m}->{foreign_class};
            $prefix    = $info->{m2m}->{map_to};
        }
        else {
            $rel_class = $info->{class};
            $prefix    = $rel;
        }
        my @rel_cols = $rel_class->columns;
        push( @fields, map { $prefix . '.' . $_ } @rel_cols );
    }
    for my $col (@cols) {
        push( @fields, 'me.' . $col );
    }

    #carp sprintf( "field_names for %s [%s] : %s",
    #    $moniker, $self->model_name, dump \@fields );

    $self->{_field_names} = \@fields;

    return \@fields;
}

=head2 create( I<context>, I<dbic_object> )

Calls insert() on I<dbic_object>.

=cut

sub create {
    my ( $self, $c, $object ) = @_;
    $object->insert;
}

=head2 read( I<context>, I<dbic_object> )

Calls find() on I<dbic_object>.

=cut

sub read {
    my ( $self, $c, $object ) = @_;

    #$object->find;    # TODO is this right? what about discard_changes()?
    $c->log->error("TODO $object does not implement find() method");
    return $object;
}

=head2 update( I<context>, I<dbic_object> )

Calls update() on I<dbic_object>.

=cut

sub update {
    my ( $self, $c, $object ) = @_;
    $object->update;
}

=head2 delete( I<context>, I<dbic_object> )

Calls delete() on I<dbic_object>.

=cut

sub delete {
    my ( $self, $c, $object ) = @_;
    $object->delete;
}

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-modeladapter-dbic at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD-ModelAdapter-DBIC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD::ModelAdapter::DBIC

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD-ModelAdapter-DBIC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD-ModelAdapter-DBIC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD-ModelAdapter-DBIC>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD-ModelAdapter-DBIC>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
