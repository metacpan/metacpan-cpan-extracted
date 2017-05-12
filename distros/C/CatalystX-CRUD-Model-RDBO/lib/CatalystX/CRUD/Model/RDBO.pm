package CatalystX::CRUD::Model::RDBO;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Model CatalystX::CRUD::Model::Utils );
use CatalystX::CRUD::Iterator;
use MRO::Compat;
use mro 'c3';
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.302';

__PACKAGE__->mk_ro_accessors(
    qw( name manager treat_like_int load_with related_load_with ));
__PACKAGE__->config( object_class => 'CatalystX::CRUD::Object::RDBO' );

=head1 NAME

CatalystX::CRUD::Model::RDBO - Rose::DB::Object CRUD

=head1 SYNOPSIS

 package MyApp::Model::Foo;
 use base qw( CatalystX::CRUD::Model::RDBO );
 __PACKAGE__->config( 
            name                => 'My::RDBO::Foo', 
            manager             => 'My::RDBO::Foo::Manager',
            load_with           => [qw( bar )],
            related_load_with   => {
                bars => ['doof']
            },
            page_size           => 50,
            );
 1;

=head1 DESCRIPTION

CatalystX::CRUD::Model::RDBO is a CatalystX::CRUD implementation for Rose::DB::Object.

=head1 CONFIGURATION

The config options can be set as in the SYNOPSIS example.

=head1 METHODS

=head2 name

The name of the Rose::DB::Object-based class that the model represents.
Accessible via name() or config->{name}.

=head2 manager

If C<manager> is not defined in config(),
the Xsetup() method will attempt to load a class
named with the C<name> value from config() 
with C<::Manager> appended.
This assumes the namespace convention of Rose::DB::Object::Manager.

If there is no such module in your @INC path, then
the fall-back default is Rose::DB::Object::Manager.

=head2 load_with

The value of C<load_with> should be an array ref of relationship
names. The array ref is passed into all the Manager
get_objects* methods as the C<with_objects> value.

=head2 related_load_with

Similar to C<load_with>, but the C<with_objects> argument is passed
in all the *_related methods. The C<related_load_with> value should
be a hash ref with keys using relationships names and the values
being array refs of relationship names in the foreign (related) classes.

=cut

=head2 Xsetup

Implements the required Xsetup() method. Instatiates the model's
name() and manager() values based on config().

=cut

sub Xsetup {
    my $self = shift;

    $self->next::method(@_);

    $self->{name} = $self->config->{name};
    if ( !$self->name ) {
        return if $self->throw_error("need to configure a Rose class name");
    }

    $self->{manager} = $self->config->{manager} || $self->name . '::Manager';

    my $name = $self->name;
    my $mgr  = $self->manager;

    eval "require $name";
    if ($@) {
        return if $self->throw_error($@);
    }

    # what kind of db driver are we using. makes a difference in make_query().
    my $db = $name->new->db;
    $self->use_ilike(1) if $db->driver eq 'pg';

    # rdbo sql uses 'ne' for not equal
    $self->ne_sign('ne');

    # cache the treat_like_int hash
    $self->_treat_like_int;

    # load the Manager
    eval "require $mgr";

    # don't fret -- just use RDBO::Manager
    if ($@) {
        $self->{manager} = 'Rose::DB::Object::Manager';
        require Rose::DB::Object::Manager;
    }

    # turn on debugging help
    if ( $ENV{CATALYST_DEBUG} && $ENV{CATALYST_DEBUG} > 1 ) {
        $Rose::DB::Object::QueryBuilder::Debug = 1;
        $Rose::DB::Object::Debug               = 1;
        $Rose::DB::Object::Manager::Debug      = 1;
    }

}

=head2 new_object( @param )

Returns a CatalystX::CRUD::Object::RDBO object.

=cut

sub new_object {
    my $self = shift;
    my $rdbo = $self->name;
    my $obj;
    eval { $obj = $rdbo->new(@_) };
    if ( $@ or !$obj ) {
        my $err = defined($obj) ? $obj->error : $@;
        return if $self->throw_error("can't create new $rdbo object: $err");
    }
    return $self->next::method( delegate => $obj );
}

=head2 fetch( @params )

If present,
@I<params> is passed directly to name()'s new() method,
and is expected to be an array of key/value pairs.
Then the load() method is called on the resulting object.

If @I<params> are not present, the new() object is simply returned,
which is equivalent to calling new_object().

All the methods called within fetch() are wrapped in an eval()
and sanity checked afterwards. If there are any errors,
throw_error() is called.

Example:

 my $foo = $c->model('Foo')->fetch( id => 1234 );
 if (@{ $c->error })
 {
    # do something to deal with the error
 }
 
B<NOTE:> If the object's presence in the database is questionable,
your controller code may want to use new_object() and then call 
load_speculative() yourself. Example:

 my $foo = $c->model('Foo')->new_object( id => 1234 );
 $foo->load_speculative;
 if ($foo->not_found)
 {
   # do something
 }

=cut

sub fetch {
    my $self = shift;
    my $obj = $self->new_object(@_) or return;

    if (@_) {
        my %v = @_;
        my $ret;
        my $name = $self->name;
        my @arg  = ();
        eval { $ret = $obj->read(@arg); };
        if ( $@ or !$ret ) {
            return
                if $self->throw_error( join( " : ", $@, "no such $name" ) );
        }

        # special handling of fetching
        # e.g. Catalyst::Plugin::Session::Store::DBI records.
        if ( $v{id} ) {

            # stringify in case it's a char instead of int
            # as is the case with session ids
            my $pid = $obj->delegate->id;
            $pid =~ s,\s+$,,;
            unless ( $pid eq $v{id} ) {

                return
                    if $self->throw_error(
                          "Error fetching correct id:\nfetched: $v{id} "
                        . length( $v{id} )
                        . "\nbut got: $pid"
                        . length($pid) );
            }
        }
    }

    return $obj;
}

=head2 search( @params )

@I<params> is passed directly to the Manager get_objects() method.
See the Rose::DB::Object::Manager documentation.

Returns an array or array ref (based on wantarray) of 
CatalystX::CRUD::Object::RDBO objects.

=cut

sub search {
    my $self = shift;
    my $objs = $self->_get_objects( 'get_objects', @_ );

    # save ourselves lots of method-call overhead.
    my $class = $self->object_class;

    my @wrapped = map { $class->new( delegate => $_ ) } @$objs;
    return wantarray ? @wrapped : \@wrapped;
}

=head2 count( @params )

@I<params> is passed directly to the Manager get_objects_count() method.
See the Rose::DB::Object::Manager documentation.

Returns an integer.

=cut

sub count {
    my $self = shift;
    return $self->_get_objects( 'get_objects_count', @_ );
}

=head2 iterator( @params )

@I<params> is passed directly to the Manager get_objects_iterator() method.
See the Rose::DB::Object::Manager documentation.

Returns a CatalystX::CRUD::Iterator object whose next() method
will return a CatalystX::CRUD::Object::RDBO object.

=cut

sub iterator {
    my $self = shift;
    my $iter = $self->_get_objects( 'get_objects_iterator', @_ );
    return CatalystX::CRUD::Iterator->new( $iter, $self->object_class );
}

=head2 search_related( I<obj>, I<relationship> )

Implements required method. Returns array or array ref based on calling
context, for objects related to I<obj> via I<relationship>. I<relationship>
should be a method name callable on I<obj>.

=head2 iterator_related( I<obj>, I<relationship> )

Like search_related() but returns an iterator.

=head2 count_related( I<obj>, I<relationship> )

Like search_related() but returns an integer.

=cut

sub _related_query {
    my ( $self, $obj, $rel_name ) = @_;
    my $c = $self->context;
    my $relationship = $self->has_relationship( $obj, $rel_name )
        or $self->throw_error("no relationship for $rel_name");

    # set the param so sort is correctly mangled in make_query()
    if ($relationship->isa(
            'Rose::DB::Object::Metadata::Relationship::ManyToMany')
        )
    {
        $c->req->params->{'cxc-m2m'} = 1;
    }
    my $query = $self->make_query;
    my @arg;
    if ( @{ $query->{query} } ) {
        @arg = ( query => $query->{query} );
    }
    for (qw( limit offset sort_by )) {

        # only want to include the sort_by if it makes sense.
        if ( $_ eq 'sort_by' ) {

            # can't reliably predict table prefixes in a m2m.
            # NOTE this effectively ignores whatever make_query did.
            if ( $c->req->params->{'cxc-m2m'} ) {
                next;
            }

            # if sort_by was derived from PK, it may refer to a parent table,
            # not the related table. So skip it unless it was explicit.
            if (    !$c->req->params->{'cxc-order'}
                and !$c->req->params->{'cxc-sort'} )
            {
                next;
            }
        }

        if ( exists $query->{$_} and length $query->{$_} ) {
            push( @arg, $_ => $query->{$_} );
        }
    }
    if ( $self->related_load_with
        && exists $self->related_load_with->{$rel_name} )
    {
        push(
            @arg,
            with_objects  => $self->related_load_with->{$rel_name},
            multi_many_ok => 1
        );
    }

    $c->log->debug( "related_query: " . dump \@arg ) if $c->debug;

    return @arg;
}

sub search_related {
    my ( $self, $obj, $rel ) = @_;
    return CatalystX::CRUD::Iterator->new(
        $obj->$rel( $self->_related_query( $obj, $rel ) ),
        $self->object_class );
}

sub iterator_related {
    my ( $self, $obj, $rel ) = @_;
    my $method = $rel . '_iterator';
    return CatalystX::CRUD::Iterator->new(
        $obj->$method( $self->_related_query( $obj, $rel ) ),
        $self->object_class );
}

sub count_related {
    my ( $self, $obj, $rel ) = @_;
    my $method = $rel . '_count';
    return $obj->$method( $self->_related_query( $obj, $rel ) );
}

=head2 find_related( I<obj>, I<relationship>, I<foreign_value> )

Implements required method. Returns array or array ref based on calling
context, for objects related to I<obj> via I<relationship>
that match I<foreign_value>. I<relationship>
should be a method name callable on I<obj>.

=cut

sub find_related {
    my ( $self, $obj, $rel, $foreign_pk_value ) = @_;
    my $relationship = $self->has_relationship( $obj, $rel )
        or $self->throw_error("no relationship for $rel");
    my $method = 'find_' . $rel;
    my $args;
    if ($relationship->isa(
            'Rose::DB::Object::Metadata::Relationship::ManyToMany')
        )
    {
        my $meta = $self->_get_rel_meta( $obj, $rel );
        $args = [ $meta->{map_to}->[1] => $foreign_pk_value ];
    }
    else {

        # all the PKs and Unique cols for the foreign class, OR'd together.
        my $pk_cols = $relationship->class->meta->primary_key_column_names;
        my $uniq_cols = [ map {@$_}
                @{ $relationship->class->meta->unique_keys_column_names } ];
        $args = [
            or => [
                map { $_ => $foreign_pk_value } ( @$pk_cols, @$uniq_cols )
            ]
        ];
    }

    #dump $args;

    my $r = $obj->$method( query => $args );

    # save ourselves lots of method-call overhead.
    my $class = $self->object_class;

    # delegate
    my @wrapped = map { $class->new( delegate => $_ ) } @$r;
    return wantarray ? @wrapped : \@wrapped;
}

=head2 add_related( I<obj>, I<rel_name>, I<foreign_value> )

Associate foreign object identified by I<foreign_value> with I<obj>
via the relationship I<rel_name>.

B<CAUTION:> For many-to-many relationships only.

=head2 rm_related( I<obj>, I<rel_name>, I<foreign_value> )

Dissociate foreign object identified by I<foreign_value> from I<obj>
via the relationship I<rel_name>.

B<CAUTION:> For many-to-many relationships only.

=cut

sub _get_rel_meta {
    my ( $self, $obj, $rel_name ) = @_;

    my $rel = $self->has_relationship( $obj, $rel_name )
        or $self->throw_error("no such relationship $rel_name");

    if ( $rel->isa('Rose::DB::Object::Metadata::Relationship::ManyToMany') ) {

        my $map_class = $rel->map_class;
        my $mcm       = $map_class->meta;
        my @map_to    = $mcm->relationship( $rel->map_to )->column_map;
        my @map_from  = $mcm->relationship( $rel->map_from )->column_map;
        my %m         = (
            map_to    => \@map_to,
            map_from  => \@map_from,
            map_class => $map_class,
        );

        #carp dump \%m;

        return \%m;

    }
    elsif ( $rel->isa('Rose::DB::Object::Metadata::Relationship::OneToMany') )
    {
        my $column_map = $rel->column_map;
        my %m          = (
            map_to => [ reverse %$column_map ],    # yes, coerce into array
        );
        return \%m;

    }
    else {
        $self->throw_error( "unsupport relationship type: " . ref($rel) );
    }
}

=head2 has_relationship( I<obj>, I<rel_name> )

Returns the Rose::DB::Object::Metadata::Relationship instance
for I<rel_name> if it exists, or undef if it does not.

=cut

sub has_relationship {
    my ( $self, $obj, $rel_name ) = @_;
    if ( !$obj ) {
        $self->throw_error("obj not defined");
    }
    return $obj->delegate->meta->relationship($rel_name);
}

sub add_related {
    my ( $self, $obj, $rel_name, $fk_val ) = @_;
    my $addmethod = 'add_' . $rel_name;
    my $meta      = $self->_get_rel_meta( $obj, $rel_name );
    my $fpk       = $meta->{map_to}->[1];
    $obj->$addmethod( { $fpk => $fk_val } );
    my $rt = $obj->save;

    # so next access reflects change.
    $obj->forget_related($rel_name);

    return $rt;
}

sub rm_related {
    my ( $self, $obj, $rel_name, $fk_val ) = @_;

    my $meta = $self->_get_rel_meta( $obj, $rel_name );
    my $obj_method = $obj->delegate->meta->column_accessor_method_name(
        $meta->{map_from}->[1] );
    my $query = [
        $meta->{map_from}->[0] => $obj->$obj_method,
        $meta->{map_to}->[0]   => $fk_val,
    ];

    #carp dump $query;

    $self->manager->delete_objects(
        object_class => $meta->{map_class},
        where        => $query,
    );

    # so next access reflects change
    $obj->forget_related($rel_name);
    return $obj;
}

=head2 make_query( I<field_names> )

Implement a RDBO-specific query factory based on request parameters.
Return value can be passed directly to search(), iterator() or count() as
documented in the CatalystX::CRUD::Model API.

See CatalystX::CRUD::Model::Utils::make_sql_query() for API details.

=cut

sub _get_field_names {
    my $self = shift;
    return $self->{_field_names} if $self->{_field_names};
    my @cols = $self->name->meta->column_names;
    $self->{_field_names} = \@cols;
    return \@cols;
}

=head2 treat_like_int

Returns hash ref of all column names that return type =~ m/^date(time)$/.
This is so that wildcard searches for date and datetime-based columns
will get proper SQL rendering.

=cut

sub _treat_like_int {
    my $self = shift;
    return $self->{treat_like_int} if $self->{treat_like_int};
    $self->{treat_like_int} = {};
    my $col_names = $self->_get_field_names;

    # treat wildcard timestamps like ints not text (>= instead of ILIKE)
    for my $name (@$col_names) {
        my $col = $self->name->meta->column($name);
        if ( $col->type =~ m/date|time|boolean|int/ ) {
            $self->{treat_like_int}->{$name} = 1;
        }
    }

    return $self->{treat_like_int};
}

sub _join_with_table_prefix {
    my ( $self, $q, $prefix ) = @_;
    return join( ', ',
        map { $prefix . '.' . $_->[0] . ' ' . $_->[1] }
        map { [%$_] } @{ $q->{sort_order} } );
}

sub make_query {
    my $self        = shift;
    my $c           = $self->context;
    my $field_names = shift || $self->_get_field_names;
    my $q           = $self->make_sql_query($field_names);

    # many2many relationships always have two tables,
    # and we are sorting by the 2nd one. The 1st one is the mapper.
    # however, we leave sort_by alone if it already has . in it,
    # since then we assume the request knew enough to ask.
    if ( length( $q->{sort_by} ) && !( $q->{sort_by} =~ m/\./ ) ) {
        if ( $c->req->params->{'cxc-m2m'} ) {
            if ( !( $q->{sort_by} =~ m/t\d\./ ) ) {
                $q->{sort_by} = $self->_join_with_table_prefix( $q, 't2' );
            }
        }
        else {
            if ( !( $q->{sort_by} =~ m/t\d\./ ) ) {
                $q->{sort_by} = $self->_join_with_table_prefix( $q, 't1' );
            }
        }
    }

    $c->log->debug("make_query: WHERE $q->{query_obj} ORDER BY $q->{sort_by}")
        if $c->debug;
    $c->log->debug( "query: " . dump $q ) if $c->debug;

    return $q;
}

sub _get_objects {
    my $self    = shift;
    my $method  = shift || 'get_objects';
    my @args    = @_;
    my $manager = $self->manager;
    my $name    = $self->name;
    my @params  = ( object_class => $name );    # not $self->object_class

    #carp dump \@args;

    if ( ref $args[0] eq 'HASH' ) {
        push( @params, %{ $args[0] } );
    }
    elsif ( ref $args[0] eq 'ARRAY' ) {
        push( @params, @{ $args[0] } );
    }
    else {
        push( @params, @args );
    }

    push(
        @params,
        with_objects  => $self->load_with,
        multi_many_ok => 1
    ) if $self->load_with;

    return $manager->$method(@params);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud-model-rdbo at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD-Model-RDBO>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD::Model::RDBO

You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD-Model-RDBO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD-Model-RDBO>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD-Model-RDBO>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD-Model-RDBO>

=back

=head1 ACKNOWLEDGEMENTS

This module is based on Catalyst::Model::RDBO by the same author.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
