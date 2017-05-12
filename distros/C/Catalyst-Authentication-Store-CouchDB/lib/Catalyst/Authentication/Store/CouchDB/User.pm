## no critic
# no critic line turns off Perl::Critic, to get rid of the warning that
# Dist::Zilla::Plugin::PkgVersion puts the package version straight
package Catalyst::Authentication::Store::CouchDB::User;
BEGIN {
  $Catalyst::Authentication::Store::CouchDB::User::VERSION = '0.001';
}
# ABSTRACT: The backing user class for the Catalyst::Authentication::Store::CouchDB storage module.
## use critic
use strict;
use warnings;

use Moose 2.000;
use MooseX::NonMoose 0.20;
use CouchDB::Client 0.09 qw ();
use Catalyst::Exception;
use Catalyst::Utils;
use JSON 2.17 qw ();
use Try::Tiny 0.09;


use namespace::autoclean;
extends 'Catalyst::Authentication::User';

has '_user'         => (is => 'rw', isa => 'CouchDB::Client::Doc', );
has '_couchdb'      => (is => 'ro', isa => 'CouchDB::Client::DB', );
has '_designdoc'    => (is => 'ro', isa => 'CouchDB::Client::DesignDoc', );
has 'view'          => (is => 'ro', isa => 'Str', required => 1, );

around BUILDARGS => sub {
    my ($orig, $class, $config, $c) = @_;

    # Allow the User Agent to be overridden - this is handy for tests to 
    # mock up the CouchDB interaction

    my $ua_class = (exists $config->{ua} ? $config->{ua} : 'LWP::UserAgent');
    Catalyst::Utils::ensure_class_loaded($ua_class);
    my $ua = $ua_class->new();

    my $couch = CouchDB::Client->new(
        uri => $config->{couchdb_uri},
        ua  => $ua,
    );

    if (!$couch->testConnection()) {
        Catalyst::Exception->throw("Could not connect to database");
    }

    my $couch_database = $couch->newDB($config->{dbname});
    my $couch_designdoc = try {
        $couch_database->newDesignDoc($config->{designdoc})->retrieve();
    };
    if (!$couch_designdoc) {
        Catalyst::Exception->throw("Could not retrieve design document");
    };

    if (!exists $couch_designdoc->views->{$config->{view}}) {
        Catalyst::Exception->throw("Design document does not contain view");
    }

    return $class->$orig(
        _couchdb    => $couch_database,
        _designdoc  => $couch_designdoc,
        view        => $config->{view},
    );

};


sub load {
    my ($self, $authinfo, $c) = @_;

    my $couch_data = try { $self->_designdoc->queryView(
            $self->view,
            include_docs    => 'true',
            limit           => 1,
            key             => $authinfo->{username},
        );
    };
    if (!$couch_data) {
        Catalyst::Exception->throw("Could not read view");
    };

    return unless exists $couch_data->{rows};
    return unless ref ( $couch_data->{rows}) eq 'ARRAY';
    return unless defined  $couch_data->{rows}->[0];
    return unless exists  $couch_data->{rows}->[0]->{doc};
    my $user_data = $couch_data->{rows}->[0]->{doc};

    my $user_doc = $self->_user_doc_from_hash($user_data);
    $self->_user($user_doc);
    return $self;
}

sub supported_features {
    my $self = shift;

    return {
        session         => 1,
        roles           => 1,
    };
}

sub id {
    my ($self) = @_;
    return $self->_user->id;
}


sub roles {
    my ($self) = shift;

    return @{$self->_user->data->{roles}};
}

sub get {
    my ($self, $field) = @_;

    return unless defined $self->_user;

    if ($field eq 'id') {
        return $self->id;
    }

    if (exists $self->_user->data->{$field}) {
        return $self->_user->data->{$field};
    }
    return;
}

sub get_object {
    my ($self, $force) = @_;

    return $self->_user;
}

sub for_session {
    my ($self) = @_;

    my $data = $self->_user->contentForSubmit();
    # Return JSON here, because it's fast, it's human readable so we can
    # see what's going on in the session.  We can't return the data structure,
    # because something in the session handling somewhere is mangling it.
    return JSON::encode_json($data);
}

sub from_session {
    my ($self, $frozen_user) = @_;

    $self->_user($self->_user_doc_from_hash(JSON::decode_json($frozen_user)));
    return $self;
}

sub AUTOLOAD {
    my ($self) = @_;

    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    return $self->get($method);
}





sub _user_doc_from_hash {
    my ($self, $user_data) = @_;

    my $id = delete($user_data->{_id});
    my $rev = delete($user_data->{_rev});
    my $attachments = delete($user_data->{_attachments});

    return $self->_couchdb->newDoc($id, $rev, $user_data, $attachments);
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;




=pod

=head1 NAME

Catalyst::Authentication::Store::CouchDB::User - The backing user class for the Catalyst::Authentication::Store::CouchDB storage module.

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The L<Catalyst::Authentication::Store::CouchDB:User> class
implements user storage connected to a CouchDB instance.

=head1 SYNPOSIS

Internal - not used directly.

=head1 METHODS

=head2 new

Constructor.  Connects to the CouchDB instance in the configuration, and
fetches the design document that contains the configured view.

=head2 load ( $authinfo, $c )

Retrieves a user from storage.  It queries the configured view, and converts
the first document retrieved into a CouchDB document.  This is then used
as the User backing object

=head2 supported_features

Indicates the features supported by this class.

=head2 roles

Returns a list of roles supported by this class.  These are stored as an array
in the 'roles' field of the User document.

=head2 for_session

Returns a serialised user for storage in the session.  This is a JSON
representation of the user.

=head2 from_session ( $frozen_user )

Given the results of for_session, deserialises the user, and recreates the backing
object.

=head2 get ( $fieldname )

Returns the field $fielname from the backing object.

=head2 AUTOLOAD

AUTOLOAD is defined so that calls to missing methods will get converted into a call to
C<get> for the field matching the method name.  This is convenient for use inside templates,
as for example C<user.name> will now return the C<name> field from the user document.

=head1 NOTES

This module is heavily based on L<Catalyst::Authentication::Store::DBIx::Class::User>.

=head1 BUGS

None known, but there are bound to be some.  Please email the author.

=head1 AUTHOR

Colin Bradford <cjbradford@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Colin Bradford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

