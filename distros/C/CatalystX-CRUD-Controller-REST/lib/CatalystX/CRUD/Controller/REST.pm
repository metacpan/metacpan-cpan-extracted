package CatalystX::CRUD::Controller::REST;
use Moose;
use namespace::autoclean;

use Data::Dump qw( dump );

BEGIN {
    extends qw( Catalyst::Controller::REST CatalystX::CRUD );
}

our $VERSION = '0.005';

__PACKAGE__->mk_accessors(
    qw(
        model_adapter
        model_name
        model_meta
        primary_key
        naked_results
        page_size
        )
);

with 'CatalystX::CRUD::ControllerRole';

use CatalystX::CRUD::Results;

=head1 NAME

CatalystX::CRUD::Controller::REST - Catalyst::Controller::REST with CRUD

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use Moose;
 use namespace::autoclean;

 BEGIN { extends 'CatalystX::CRUD::Controller::REST' }
     
 __PACKAGE__->config(
    model_name      => 'Foo',
    primary_key     => 'id',
    page_size       => 50,
 );
    
 1;
    
 # now you can manage Foo objects with URIs like:
 # POST      /foo                -> create new Foo record
 # GET       /foo                -> list all Foo records
 # PUT       /foo/<pk>           -> create or update Foo record (idempotent)
 # DELETE    /foo/<pk>           -> delete Foo record
 # GET       /foo/<pk>           -> view Foo record 
 # GET       /foo/<pk>/bar       -> view Bar object(s) related to Foo
 # POST      /foo/<pk>/bar       -> create Bar object related to Foo
 # GET       /foo/<pk>/bar/<pk2> -> view Bar with id <pk2> related to Foo with <pk>
 # POST      /foo/<pk>/bar/<pk2> -> create relationship between Foo <pk> and Bar <pk2>
 # DELETE    /foo/<pk>/bar/<pk2> -> sever Bar object relationship to Foo
 # PUT       /foo/<pk>/bar/<pk2> -> create/update Bar object related to Foo (idempotent)
 # GET       /foo/search         -> search for Foo objects
 # GET       /foo/count          -> search for Foo objects, returning count only

=head1 DESCRIPTION

Subclass of Catalyst::Controller::REST for use with CatalystX::CRUD.

=head1 DISCLAIMERS

This module is B<not> to be confused with CatalystX::CRUD::REST.
This is not a drop-in replacement for existing CatalystX::CRUD::Controllers.

This module extends Catalyst::Controller::REST to work with the
CatalystX::CRUD::Controller API. It is designed for web services,
not managing CRUD actions via HTML forms.

This is B<not> a subclass of CatalystX::CRUD::Controller.

=cut

=head1 METHODS

=cut

##############################################################
# Local actions

=head2 search_objects

Registers URL space for B<search>.

=cut

sub search_objects : Path('search') : Args(0) : ActionClass('REST') {
}

=head2 search_objects_GET

Query the model and return results. See do_search().

=cut

sub search_objects_GET {
    my ( $self, $c ) = @_;
    $self->do_search($c);
    if ( !blessed( $c->stash->{results} ) ) {
        $self->status_bad_request( $c,
            message => 'Must provide search parameters' );
    }
    else {
        $self->status_ok( $c, entity => $c->stash->{results}->serialize );
    }
}

=head2 count_objects

Registers URL space for B<count>.

=cut

sub count_objects : Path('count') : Args(0) : ActionClass('REST') {
}

=head2 count_objects_GET

Like search_objects_GET() but does not set result values, only a total count.
Useful for AJAX-y types of situations where you want to query for a total
number of matches and create a pager but not actually retrieve any data.

=cut

sub count_objects_GET {
    my ( $self, $c ) = @_;
    $c->stash( fetch_no_results => 1 );    # optimize a little
    $self->do_search($c);
    if ( !blessed( $c->stash->{results} ) ) {
        $self->status_bad_request( $c,
            message => 'Must provide search parameters' );
    }
    else {
        $self->status_ok( $c, entity => $c->stash->{results}->serialize );
    }
}

##############################################################
# REST actions

=head2 zero_args

Registers URL space for 0 path arguments.

=cut

sub zero_args : Path('') : Args(0) : ActionClass('REST') {
}

=head2 zero_args_GET( I<ctx> )

GET /foo -> list objects of type foo.

Calls do_search().

=cut

sub zero_args_GET {
    my ( $self, $c ) = @_;
    $self->do_search($c);
    $self->status_ok( $c, entity => $c->stash->{results}->serialize );
}

=head2 zero_args_POST( I<ctx> )

POST /foo -> create object of type foo.

=cut

sub zero_args_POST {
    my ( $self, $c ) = @_;

    unless ( $self->can_write($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    $c->stash( object => $self->do_model( $c, 'fetch' ) );
    if ( my $obj = $self->save_object($c) ) {
        my $pk = $self->make_primary_key_string($obj);
        $self->status_created(
            $c,
            location => $c->uri_for($pk),
            entity   => $c->stash->{object}->serialize
        );
    }
    else {

        # TODO msg
        $self->status_bad_request( $c, message => 'Failed to create' );
    }
}

=head2 one_arg

Registers URL space for 1 path argument.

=cut

sub one_arg : Path('') : Args(1) : ActionClass('REST::ForBrowsers') {
    my ( $self, $c, $id ) = @_;
    $self->fetch( $c, $id );
}

=head2 one_arg_GET( I<ctx>, I<pk> )

GET /foo/<pk> -> retrieve object for I<pk>.

=cut

sub one_arg_GET {
    my ( $self, $c, $id ) = @_;
    return if $c->stash->{fetch_failed};
    return if $c->stash->{object}->is_new;    # 404
    $self->status_ok( $c, entity => $c->stash->{object}->serialize );
}

=head2 one_arg_PUT( I<ctx>, I<pk> )

PUT /foo/<pk> -> create or update the object for I<pk>.

This method must be idempotent. POST is not.

=cut

sub one_arg_PUT {
    my ( $self, $c, $id ) = @_;
    return if $c->stash->{fetch_failed};

    # remember if we're creating or updating
    my $obj_is_new = $c->stash->{object}->is_new;

    unless ( $self->can_write($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    if ( my $obj = $self->save_object($c) ) {
        if ( !$obj_is_new ) {
            $self->status_ok( $c, entity => $obj->serialize );
        }
        else {
            my $loc = $c->uri_for($id);
            $c->log->debug("PUT location=$loc") if $c->debug;
            $self->status_created(
                $c,
                location => $loc,
                entity   => $obj->serialize,
            );
        }
    }
    else {

        # TODO msg
        $self->status_bad_request( $c, message => 'Failed to update' );
    }
}

=head2 one_arg_DELETE( I<ctx>, I<pk> )

DELETE /foo/<pk> -> delete the object for I<pk>.

=cut

sub one_arg_DELETE {
    my ( $self, $c, $id ) = @_;
    return if $c->stash->{fetch_failed};

    unless ( $self->can_write($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    if ( $self->delete_object($c) ) {
        $self->status_no_content($c);
    }
    else {

        # TODO msg
        $self->status_bad_request( $c, message => 'Failed to delete' );
    }
}

=head2 two_args

Registers URL space for 2 path arguments.

=cut

sub two_args : Path('') : Args(2) : ActionClass('REST::ForBrowsers') {
    my ( $self, $c, $id, $rel ) = @_;
    $c->stash( rel_name => $rel );
    $self->fetch( $c, $id );
}

=head2 two_args_GET( I<ctx>, I<pk>, I<rel> )

GET /foo/<pk>/bar -> a list of objects of type bar related to foo.

=cut

sub two_args_GET {
    my ( $self, $c, $id, $rel ) = @_;
    return if $c->stash->{fetch_failed};
    my $results
        = $self->do_model( $c, 'iterator_related', $c->stash->{object}, $rel,
        );
    if ( $self->has_errors($c) ) {
        my $err = $c->error->[0];
        if ( $err =~ m/^(unsupported relationship name: (\S+))/i ) {
            $self->status_not_found( $c, message => $1 );
        }
        else {
            $self->status_bad_request( $c, message => $err );
        }
        $c->clear_errors;
    }
    else {
        $self->status_ok( $c, entity => $results->serialize );
    }
}

=head2 two_args_POST( I<ctx>, I<pk>, I<rel> )

POST /foo/<pk>/bar  -> create relationship between foo and bar.

B<TODO> This method calls a not-yet-implemented create_related()
action in the CXC::Model.

=cut

sub two_args_POST {
    my ( $self, $c, $id, $rel ) = @_;
    return if $c->stash->{fetch_failed};
    unless ( $self->can_write($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    if ( !$self->model_can( $c, 'create_related' ) ) {
        $self->status_bad_request( $c,
            message =>
                'This server does not yet implement the required method create_related'
        );
        return;
    }

    my $rel_obj
        = $self->do_model( $c, 'create_related', $c->stash->{object}, $rel, );
    if ($rel_obj) {

        # this controller doesn't know anything about the PK for $rel,
        # so assume the object can give us a PK.
        my $rel_id = $rel_obj->primary_key_uri_escaped;
        $self->status_created(
            $c,
            location =>
                $c->uri_for( sprintf( "%s/%s/%s", $id, $rel, $rel_id ) ),
            entity => $rel_obj->serialize
        );
    }
    else {

        # TODO msg
        $self->status_bad_request( $c, message => 'Failed to create' );
    }

}

=head2 three_args

Registers the URL space for 3 path arguments.

=cut

sub three_args : Path('') : Args(3) : ActionClass('REST::ForBrowsers') {
    my ( $self, $c, $id, $rel, $rel_id ) = @_;
    $c->stash( rel_name         => $rel );
    $c->stash( foreign_pk_value => $rel_id );
    $self->fetch( $c, $id );
}

=head2 three_args_GET( I<ctx>, I<pk>, I<rel>, I<rel_id> )

GET /foo/<pk>/<re>/<pk2>

=cut

sub three_args_GET {
    my ( $self, $c, $id, $rel, $rel_id ) = @_;
    return if $c->stash->{fetch_failed};
    my $result = $self->do_model( $c, 'find_related', $c->stash->{object},
        $rel, $rel_id, );
    if ( !$result or ( ref $result eq 'ARRAY' and !@$result ) ) {
        my $err_msg = sprintf( "No such %s with id '%s'", $rel, $rel_id );
        $self->status_not_found( $c, message => $err_msg );
    }
    else {

        # coerce $result into an array ref for consistency
        if ( ref $result ne 'ARRAY' ) {
            $result = [$result];
        }

        my @entity;
        for my $r (@$result) {
            push @entity, $r->serialize;
        }
        $self->status_ok( $c, entity => \@entity );
    }
}

=head2 three_args_DELETE( I<ctx>, I<pk>, I<rel>, I<rel_pk> )

DELETE /foo/<pk>/bar/<pk2> -> sever 'bar' object relationship to 'foo'

=cut

sub three_args_DELETE {
    my ( $self, $c, $id, $rel, $rel_id ) = @_;
    return if $c->stash->{fetch_failed};
    unless ( $self->can_write($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    my $rt = $self->do_model( $c, 'rm_related', $c->stash->{object},
        $rel, $rel_id, );
    if ($rt) {
        $self->status_no_content($c);
    }
    else {

        # TODO msg
        $self->status_bad_request( $c,
            message => 'Failed to remove relationship' );
    }
}

=head2 three_args_POST( I<ctx>, I<pk>, I<rel>, I<rel_pk> )

POST /foo/<pk>/bar/<pk2> -> create relationship between 'foo' and 'bar'

=cut

sub three_args_POST {
    my ( $self, $c, $id, $rel, $rel_id ) = @_;
    return if $c->stash->{fetch_failed};
    my $rt = $self->do_model( $c, 'add_related', $c->stash->{object},
        $rel, $rel_id, );
    if ($rt) {
        $self->status_no_content($c);
    }
    else {

        # TODO msg
        $self->status_bad_request( $c,
            message => 'Failed to create relationship' );
    }
}

=head2 three_args_PUT( I<ctx>, I<pk>, I<rel>, I<rel_pk> )

PUT /foo/<pk>/bar/<pk2> -> create/update 'bar' object related to 'foo'

=cut

sub three_args_PUT {
    my ( $self, $c, $id, $rel, $rel_id ) = @_;
    return if $c->stash->{fetch_failed};
    my $rt = $self->do_model( $c, 'put_related', $c->stash->{object},
        $rel, $rel_id, );

    if ($rt) {
        $self->status_no_content($c);
    }
    else {

        # TODO msg
        $self->status_bad_request( $c,
            message => 'Failed to PUT relationship' );
    }
}

##########################################################
# CRUD methods

=head2 save_object( I<ctx> )

Calls can_write(), inflate_object(), precommit(), create_or_update_object()
and postcommit().

=cut

sub save_object {
    my ( $self, $c ) = @_;
    unless ( $self->can_write($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    # get a valid object
    my $obj = $self->inflate_object($c);
    if ( !$obj ) {
        $c->log->debug("inflate_object() returned false") if $c->debug;
        return 0;
    }

    # write our changes
    unless ( $self->precommit( $c, $obj ) ) {
        return 0;
    }
    $self->create_or_update_object( $c, $obj );
    $self->postcommit( $c, $obj );
    return $obj;
}

=head2 create_or_update_object( I<ctx>, I<object> )

Calls the update() or create() method on the I<object> (or model_adapter()),
picking the method based on whether C<object_id> in stash() 
evaluates true (update) or false (create).

=cut

sub create_or_update_object {
    my ( $self, $c, $obj ) = @_;
    my $method = $obj->is_new ? 'create' : 'update';
    $c->log->debug("object->$method") if $c->debug;
    if ( $self->model_adapter ) {
        $self->model_adapter->$method( $c, $obj );
    }
    else {
        $obj->$method;
    }
}

=head2 delete_object( I<ctx> )

Checks can_write(), precommit(), and if both true,
calls the delete() method on the B<object> in the stash().

=cut

sub delete_object {
    my ( $self, $c ) = @_;
    unless ( $self->can_write($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    my $o = $c->stash->{object};

    unless ( $self->precommit( $c, $o ) ) {
        return 0;
    }
    if ( $self->model_adapter ) {
        $self->model_adapter->delete( $c, $o );
    }
    else {
        $o->delete;
    }
    $self->postcommit( $c, $o );
    return 1;
}

=head2 inflate_object( I<ctx> )

Returns the object from stash() initialized with the request data.

=cut

sub inflate_object {
    my ( $self, $c ) = @_;
    my $object = $c->stash->{object};
    if ( !$object ) {
        $self->throw_error("object not set in stash");
    }
    my $req_data = $c->req->data;
    if ( !$req_data ) {
        $self->status_bad_request( $c, message => 'Missing request data' );
        return;
    }

    # TODO other sanity checks?

    for my $f ( keys %$req_data ) {
        if ( $object->can($f) ) {
            $object->$f( $req_data->{$f} );
        }
    }
    return $object;
}

=head2 can_read( I<ctx> )

Returns true if the current request is authorized to read() the C<object> in
stash().

Default is true.

=cut

sub can_read {1}

=head2 can_write( I<ctx> )

Returns true if the current request is authorized to create() or update()
the C<object> in stash().

Default is true.

=cut

sub can_write {1}

=head2 precommit( I<ctx>, I<object> )

Called by save_object(). If precommit() returns a false value, save_object() is aborted.
If precommit() returns a true value, create_or_update_object() gets called.

The default return is true.

=cut

sub precommit {1}

=head2 postcommit( I<cxt>, I<obj> )

Called internally inside save_object(). Our default just returns true.
Override this method to post-process a successful save_object() action.

=cut

sub postcommit {1}

=head2 fetch( I<ctx>, I<pk> )

Determines the correct value and field name for I<pk>
and calls the do_model() method for C<fetch>.

On success, the B<object> key will be set in stash().

On failure, calls status_not_found() and sets the
B<fetch_failed> stash() key.

=cut

sub fetch {
    my ( $self, $c, $id ) = @_;

    unless ( $self->can_read($c) ) {
        $self->status_forbidden( $c, message => 'Permission denied' );
        return;
    }

    $c->stash->{object_id} = $id;
    my @pk = $self->get_primary_key( $c, $id );

    # make sure all elements of the @pk pairs are not-null
    if ( scalar(@pk) % 2 ) {
        $self->throw_error(
            "Odd number of elements returned from get_primary_key()");
    }
    my %pk_pairs = @pk;
    my $pk_is_null;
    for my $key ( keys %pk_pairs ) {
        my $val = $pk_pairs{$key};
        if ( !defined($val) or !length($val) ) {
            $pk_is_null = $key;
            last;
        }
    }
    if ( $c->debug and defined $pk_is_null ) {
        $c->log->debug("Null PK value for '$pk_is_null'");
    }
    my @arg = ( defined $pk_is_null || !$id ) ? () : (@pk);
    $c->log->debug( "fetch: " . dump \@arg ) if $c->debug;
    $c->stash->{object} = $self->do_model( $c, 'fetch', @arg );
    if ( !$c->stash->{object} ) {
        my $err_msg
            = sprintf( "No such %s with id '%s'", $self->model_name, $id );
        $self->status_not_found( $c, message => $err_msg );
        $c->log->error($err_msg);
        $c->stash( fetch_failed => 1 );
        $c->clear_errors;
        return 0;
    }
    if ( $self->has_errors($c) ) {
        $c->log->debug("errors in fetch") if $c->debug;
    }
    return $c->stash->{object};
}

=head2 do_search( I<ctx>, I<arg> )

Prepare and execute a search. Called internally by list()
and search().

Results are saved in stash() under the C<results> key.

If B<naked_results> is true, then results are set just as they are
returned from search() or list() (directly from the Model).

If B<naked_results> is false (default), then results is a
CatalystX::CRUD::Results object.

=cut

sub do_search {
    my ( $self, $c, @arg ) = @_;

    # if we have no input, just return for initial search
    if ( !@arg && !$c->req->param && $c->action->name eq 'search' ) {
        return;
    }

    my $query;
    if ( $self->can('make_query') ) {
        $query = $self->make_query( $c, @arg );
    }
    elsif ( $self->model_can( $c, 'make_query' ) ) {
        $query = $self->do_model( $c, 'make_query', @arg );
    }
    else {
        $self->throw_error(
            "neither controller nor model implement a make_query() method");
    }
    my $count = $self->do_model( $c, 'count', $query ) || 0;
    my $results;
    unless ( $c->stash->{fetch_no_results} ) {
        $results = $self->do_model( $c, 'search', $query );
    }

    my $pager;
    if ( $count && $self->model_can( $c, 'make_pager' ) ) {
        $pager = $self->do_model( $c, 'make_pager', $count, $results );
    }

    my $r
        = $self->naked_results
        ? $results
        : CatalystX::CRUD::Results->new(
        {   count   => $count,
            pager   => $pager,
            results => $results,
            query   => $query,
        }
        );
    $c->stash( results => $r );

}

=head2 do_model( I<ctx>, I<args> )

Wrapper around the ControllerRole method of the same name.
The wrapper does an eval and sets the I<ctx> error param
with $@.

=cut

around 'do_model' => sub {
    my ( $orig, $self, $c, @args ) = @_;
    my $results;
    eval { $results = $self->$orig( $c, @args ); };
    if ($@) {
        $c->error($@);    # re-throw
        return $results;
    }
    return $results;
};

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalystx-crud-controller-rest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD-Controller-REST>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD::Controller::REST


You can also look for information at:

=over 4

=item * Mailing List

L<https://groups.google.com/forum/#!forum/catalystxcrud>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD-Controller-REST>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD-Controller-REST>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD-Controller-REST>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD-Controller-REST/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
