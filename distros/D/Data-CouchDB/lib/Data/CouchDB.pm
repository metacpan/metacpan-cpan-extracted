package Data::CouchDB;

use 5.006;
use strict;
use warnings;

=head1 NAME

Data::CouchDB - CouchDB document management

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 NAME

Data::CouchDB

=head1 SYNOPSYS

    my $couchdb = Data::CouchDB->new(
        replica_host => 'localhost',
        replica_port => 5432,
        master_host  => 'localhost',
        master_port  => 5432,
        couch        => 'testdb',
    );

=head1 DESCRIPTION

This class represents couchdb as a datasource.

=head1 ATTRIBUTES

=cut

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use Cache::RedisDB;
use Data::CouchDB::Connection;
use Try::Tiny;
use LWP::UserAgent;

has name => (
    is  => 'ro',
    isa => 'Str'
);

=head2 db

db with which to operate.

=cut

has db => (
    is      => 'ro',
    isa     => 'Str',
    default => 'db',
);

=head2 couchdb

password for "couchdb" user

=cut

has couchdb => (
    is      => 'ro',
    default => 'TESTPASS',
);

=head2 replica_host

name of the host to read from.

=cut

has 'replica_host' => (
    is      => 'ro',
    default => 'localhost',
);

=head2 replica_port

port number in replica_host through which we can read.

=cut

has replica_port => (
    is      => 'ro',
    default => '5984',
);

=head2 replica_protocol

 protcol used to read.

=cut

has replica_protocol => (
    is  => 'ro',
    isa => 'Str',
);

=head2 master_host

name of the host to write to

=cut

has 'master_host' => (
    is      => 'ro',
    default => 'localhost',
);

=head2 master_port

port number in master_host through which we can write.

=cut

has master_port => (
    is      => 'ro',
    default => '5984',
);

=head2 master_protocol

protocol used to write.

=cut

has master_protocol => (
    is  => 'ro',
    isa => 'Str',
);

=head2 replica

The internal ds used to read from couchdb

=cut

has replica => (
    is         => 'ro',
    isa        => 'Data::CouchDB::Connection',
    lazy_build => 1,
);

=head2 master

The internal ds used to write to couchdb

=cut

has master => (
    is         => 'ro',
    isa        => 'Data::CouchDB::Connection',
    lazy_build => 1,
);

=head2 ua

Optionally passed ua(user_agent). If not passed the couchdb's default ua is used.

=cut

has ua => (
    is  => 'ro',
    isa => 'Maybe[LWP::UserAgent]',
);

=head1 METHODS

=head2 document

Get or set a couch document.

Usage,
    To get a document
        $couchdb->document($doc_id);

    To set a document
        $couchdb->document($doc_id, $data);

        $data is a HashRef


=cut

my $cache_namespace = 'COUCH_DOCS';

sub document {
    my $self = shift;
    my $doc  = shift;
    my $data = shift;

    my $cache_key = $self->db . '_' . $doc;
    if ($data) {
        Cache::RedisDB->del($cache_namespace, $cache_key) if ($self->_can_cache);
        $data = $self->master->document($doc, $data);
    } else {
        $data = Cache::RedisDB->get($cache_namespace, $cache_key) if ($self->_can_cache);

        if (not $data) {
            $data = $self->replica->document($doc);
            Cache::RedisDB->set($cache_namespace, $cache_key, $data, 127)
                if ($data and $self->_can_cache);
        }
    }

    return $data;
}

=head2 view

Query a couchdb view

Usage,
    Without Parameters
        $couchdb->view($db, $viewname);

    With Parameters
        $couchdb->view($db, $viewname, $parameters);

        $parameters is a HashRef


=cut

sub view {
    my $self   = shift;
    my $view   = shift;
    my $params = shift;

    return $self->replica->view($view, $params);
}

=head2 document_present

A syntatic sugar to check if a document

Usage,
    if ($couchdb->document_present($doc_id)) {
        ....
    }

Throws,
    Nothing

Returns,
    1     - if document is found.
    undef - if document is not found.

=cut

sub document_present {
    my $self = shift;
    my $doc  = shift;

    try { $self->replica->document($doc); } or return;

    return 1;
}

=head2 create_document

Creates a couch document

Usage,
    my $doc_id = $couchdb->create_document($doc_id);

=cut

sub create_document {
    my $self = shift;
    my $doc  = shift;

    return $self->master->create_document($doc);
}

=head2 delete_document

Deletes a couch document

Usage,
    $couchdb->delete_document($doc_id);

=cut

sub delete_document {
    my $self = shift;
    my $doc  = shift;

    return $self->master->delete_document($doc);
}

=head2 create_database

Creates a CouchDB Database.

Usage,
    $couchdb->create_database();

=cut

sub create_database {
    my $self = shift;
    return $self->master->create_database();
}

=head2 can_read

Confirms that you can read from this couchdb

Usage,
    if($couchdb->can_read) {
        ...
    }

Returns,
    1     - can read
    undef - otherwise
=cut

sub can_read {
    my $self = shift;
    return $self->replica->can_connect;
}

=head2 can_write

Confirms that you can write to this couchdb

Usage,
    if($couchdb->can_write) {
        ...
    }

Returns,
    1     - can write
    undef - otherwise

=cut

sub can_write {
    my $self = shift;
    return $self->master->can_connect;
}

sub _build_replica {
    my $self   = shift;
    my $params = {};

    $params->{host} = $self->replica_host;
    $params->{port} = $self->replica_port;
    $params->{db}   = $self->db;

    $params->{protocol} = $self->replica_protocol if ($self->replica_protocol);
    $params->{couchdb}  = $self->couchdb          if ($self->couchdb);

    return Data::CouchDB::Connection->new(%$params);
}

sub _build_master {
    my $self   = shift;
    my $params = {};

    $params->{host} = $self->master_host;
    $params->{port} = $self->master_port;
    $params->{db}   = $self->db;

    $params->{protocol} = $self->master_protocol if ($self->master_protocol);
    $params->{couchdb}  = $self->couchdb         if ($self->couchdb);

    return Data::CouchDB::Connection->new(%$params);
}

has '_can_cache' => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build__can_cache {
    return try { Cache::RedisDB::redis_connection(); 1; };
}

__PACKAGE__->meta->make_immutable;


=head1 AUTHOR

Binary.com, C<< <support at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-couchdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-CouchDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::CouchDB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-CouchDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-CouchDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-CouchDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-CouchDB/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Data::CouchDB
