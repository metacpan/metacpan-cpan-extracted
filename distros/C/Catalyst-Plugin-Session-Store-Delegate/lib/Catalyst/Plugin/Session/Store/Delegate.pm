#!/usr/bin/perl

package Catalyst::Plugin::Session::Store::Delegate;

use Moose;
use MRO::Compat;
use namespace::clean -except => 'meta';

extends 'Catalyst::Plugin::Session::Store';
with 'MooseX::Emulate::Class::Accessor::Fast';

our $VERSION = "0.06";

__PACKAGE__->mk_accessors(qw/_session_store_delegate/);

sub session_store_model_name {
    my $c = shift;
    $c->_session_plugin_config->{model} || "Sessions";
}

sub session_store_model {
    my ( $c, $id ) = @_;

    # $id may be used in for e.g. keyspace partitioning
    my $name = $c->session_store_model_name;
    $c->model( $name, $id ) || die "Couldn't find a model named $name";
}

sub session_store_delegate {
    my ( $c, $id ) = @_;

    my $obj = $c->_session_store_delegate;

    unless($obj) {
        unless ($id) {
            $c->create_session_id_if_needed;
            $id = $c->sessionid;
        }

        $obj = $c->get_session_store_delegate($id);
        $c->_session_store_delegate($obj)
    }

    return $obj;
}

sub get_session_store_delegate {
    my ( $c, $id ) = @_;

    # $model is not necessarily a catalyst model, just something that can
    # ->get_session_store_delegate($id)
    my $model = $c->session_store_model($id);

    # allow methods or arbitrary code refs
    my $method = $c->_session_plugin_config->{get_delegate} || "get_session_store_delegate";
    $model->$method($id) || die "couldn't get delegate from model: $model with method: $method";
}

sub _clear_session_instance_data {
    my ( $c, @args ) = @_;
    my $ret = $c->maybe::next::method(@args); # let the session plugin do it's thing
    
    my $delegate = $c->_session_store_delegate;
    $c->_session_store_delegate(undef);
    $c->finalize_session_delegate($delegate) if $delegate;

    return $ret;
}

sub finalize_session_delegate {
    my ( $c, $obj ) = @_;
    $obj->flush;
}

sub session_store_delegate_key_to_accessor {
    my ( $self, $key, $operation, @args ) = @_;
    my ( $field, $id ) = split(':', $key, 2);
    return ( $field, ($operation eq "delete" ? (undef, @args) : @args ) ); # delete is effectively set to undef
    # return ( join("_", $operation, $field) ); # for (get|set|delete)_foo type accessors
    # return ( $operation, $field ) # for get("foo"), set("foo") type accessors
}

sub get_session_data {
    my ( $c, $key ) = @_;
    my ( $accessor, @args ) = $c->session_store_delegate_key_to_accessor($key, "get");

    $c->session_store_delegate->$accessor(@args);
}

sub store_session_data {
    my ( $c, $key, $value ) = @_;
    my ( $accessor, @args ) = $c->session_store_delegate_key_to_accessor($key, "set", $value);

    $c->session_store_delegate->$accessor(@args);
}

sub delete_session_data {
    my ( $c, $key ) = @_;
    my ( $accessor, @args ) = $c->session_store_delegate_key_to_accessor($key, "delete");

    $c->session_store_delegate->$accessor(@args);
}

sub delete_expired_sessions {
    my $c = shift;

    my $model = $c->session_store_model;

    if ( eval { $model->can("delete_expired_sessions") } ) {
        $model->delete_expired_sessions;
    }
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::Store::Delegate - Delegate session storage to an
application model object.

=head1 SYNOPSIS

	use Catalyst::Plugin::Session::Store::Delegate;

=head1 DESCRIPTION

This store plugins makes delegating session storage to a first class object
model easy.

=head1 THE MODEL

The model is used to retrieve the delegate object for a given session ID.

This is normally something like DBIC's resultset object.

The model must respond to the C<get_delegate> method or closure in the sesion
config hash (defaults to C<get_session_store_delegate>).

An object B<must always> be returned from this method, even if it means
autovivifying. The object may optimize and create itself lazily in the actual
store only when ->store methods are actually called.

=head1 THE DELEGATE

A single delegate belongs to a single session ID. It provides storage space for
arbitrary fields.

The delegate object must respond to method calls as per the
C<session_store_delegate_key_to_accessor> method's return values.

Typically this means responding to $obj->$field type accessors.

If necessary, the delegate should maintain an internal reference count of the
stored fields, so that it can garbage collect itself when all fields have been
deleted.

The fields are arbitrary, and are goverend by the various session plugins.

The basic keys that must be supported are:

=over 4

=item expires

A timestamp indicating when the session will expire.

If a store so chooses it may clean up session data after this timestamp, even
without being told to delete.

=item session

The main session data hash.

Might not be used, if only C<flash> exists.

=item flash

A hash much like the main session data hash, which can be created and deleted
multiple times per session, as required.

=back

The delegate must also respond to the C<flush> method which is used to tell the
store delegate that no more set/get/delete methods will be invoked on it.

=head1 METHODS

=over 4

=item session_store_delegate_key_to_accessor $key, $operation

This method implements the various calling conventions. It accepts a key and an
operation name (C<get>, C<set> or C<delete>), and must return a method (could
be a string or a code reference), and an optional list of arguments that will
be invoked on the delegate.

The default version splits $key on the first colon, extracting the field name
and the ID. It then returns the unaltered field name, and if the operation is
'delete' also provides the extra argument C<undef>. This works with accessor
semantics like these:

    $obj->foo;
    $obj->foo("bar");
    $obj->foo(undef);

To facilitate a convention like
    
    $obj->get_foo;
    $obj->set_foo("bar");
    $obj->delete_foo;

or

    $obj->get("foo");
    $obj->set("foo", "bar");
    $obj->delete("foo");

simply override this method. You may look in the source of this module to find
commented out versions which should help you.

=item session_store_delegate

This method returns the delegate, which may be cached in C<$c>.

=item get_session_store_delegate $id

This method should get the delegate object for a given ID. See L</"THE MODEL">
for more details.

=item session_store_model

This method should return the model that will provide the delegate object.The
default implementation will simply return
C<< $c->model( $c->session_store_model_name ) >>.

=item session_store_model_name

Returns C<< $c->config->{session}{model_name} || "Sessions" >>.

=item finalize_session_delegate $delegate

Invokes the C<flush> method on the delegate. May be overridden if that behavior
is inappropriate.

=item get_session_data $key

=item store_session_data $key, $value

=item delete_session_data $key

These methods translate the store API into the delegate API using
C<session_store_delegate_key_to_accessor>.

=back

=cut

=head1 AUTHORS

Yuval Kogman, C<nothingmuch@woobling.org>

Tomas Doran, (t0m) C<bobtfish@bobtfish.net> (current maintainer)

=head1 COPYRIGHT & LICENSE 

Copyright (c) 2006 the aforementioned authors. 
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

