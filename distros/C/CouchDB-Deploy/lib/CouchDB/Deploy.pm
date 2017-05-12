
package CouchDB::Deploy;

use strict;
use warnings;

our $VERSION = '0.03';

use CouchDB::Client;
use CouchDB::Deploy::Process;
use Carp            qw(confess);
use Sub::Exporter -setup => {
    exports => [
        db          => \&_build_db,
        containing  => \&_build_containing,
        doc         => \&_build_doc,
        design      => \&_build_design,
        file        => \&_build_file,
        base64      => \&_build_base64,
    ],
    groups  => {
        default => [qw(db containing doc design file base64)],
    },
};

my $p;
BEGIN {
    my $server = $ARGV[0] || $ENV{COUCHDB_DEPLOY_SERVER} || 'http://localhost:5984/';
    confess "No server provided." unless $server;
    $p = CouchDB::Deploy::Process->new($server);
}

sub _build_db {
    return sub ($$) {
        my ($db, $sub) = @_;
        $p->createDBUnlessExists($db);
        $sub->();
    };
}

sub _build_containing { # syntax sugar
    return sub (&) {
        my $sub = shift;
        return $sub;
    };    
}

sub _build_doc {
    return sub (&) {
        my $sub = shift;
        my %data = $sub->();
        my $id = delete($data{_id}) || confess "Document requires an '_id' field.";
        confess "Document must not have a '_rev' field." if $data{_rev};
        my $att = delete($data{_attachments}) || {};
        $p->addDocumentUnlessExistsOrSame($id, \%data, $att);
    };
}

sub _build_design {
    return sub (&) {
        my $sub = shift;
        my %data = $sub->();
        my $id = delete($data{_id}) || confess "Design document requires an '_id' field.";
        $id = "_design/$id" unless $id =~ m{^_design/};
        $p->addDesignDocUnlessExistsOrSame($id, \%data);
    };
}

sub _build_file {
    return sub ($) {
        my $file = shift;
        return $p->getFile($file);
    };
}

sub _build_base64 {
    return sub ($) {
        my $content = shift;
        return CouchDB::Client::Doc->toBase64($content);
    };
}


1;

=pod

=head1 NAME

CouchDB::Deploy - Simple configuration scripting to deploy CouchDB databases

=head1 SYNOPSIS

    use CouchDB::Deploy;

    db 'my-test-db/', containing {
        doc {
            _id     => 'foo',
            key     => 'value',
            _attachments => {
                'foo.txt'   => {
                    content_type    => 'text/plain',
                    data            => 'RGFodXRzIEZvciBXb3JsZCBEb21pbmF0aW9uXCE=',
                },
                'bar.svg'   => {
                    content_type    => 'image/svg+xml',
                    data            => file 'dahut.svg',
                },
                'circle.html'   => {
                    content_type    => 'text/html;charset=utf-8',
                    data            => base64 <<EOHTML,
                                            <p>Hello!</p>
    EOHTML
                },
            },
        };
        design {
            _id         => '_design/dahuts',
            language    => 'javascript',
            views   => {
                'all'   => {
                    map     => "function(doc) { if (doc.type == 'dahut')  emit(null, doc) }",
                },
            },
        };
    };
    
    # then run the above as
    
    my-db-config.pl http://my.server:5984/

=head1 DESCRIPTION

This module attempts to help with the common issue of deploying databases and updates to
database schemata in distributed development settings (which can simply be when you have
your own dev box and a server to deploy to).

CouchDB does not have schemata, but it does have views (in design documents) on which
methods in your code are likely to rely. At times, you may also wish to have a given 
document in a database, say the default configuration.

What this module does is:

=over

=item *

Check that a given database exists, and create it if not

=item *

Check that a given document exists and has the same content as the one provided, and
create or update it if not

=item *

Check that a given design document exists and has the same content as the one provided, and
create or update it if not

=item *

Provide a simple helper for attachments and the specific base64 that CouchDB requires.

=back

Currently this is done in Perl, using simple syntax sugar but it is expected that it will
be updated to also support a Config::Any approach.

=head1 SYNTAX SUGAR

=over 8

=item db $DATABASE, containing { CONTENT }

Creates a database with the given name, and adds the content, unless it exists. Keep in mind
that CouchDB databases must have a trailing slash in their names.

=item doc { CONTENT }

Creates a document with that content, unless it is there and up to date. Note that currently
only documents with an _id field are supported (otherwise we couldn't do the create-unless-exists
logic). The content is of the exact same structure as the JSON one would post to CouchDB.

=item file $PATH

Reads the file at $PATH, converts it to base64, and returns that on a single line. This is a
helper made to assist in creating CouchDB attachments. Note that in the current state it will
read the file into memory.

=item base64 $CONTENT

Returns the content encoded in single-line Base 64.

=item design { CONTENT }

Creates a design document with those views and parameters, unless it is there and up to date.
The content is of the exact same structure as the JSON one would post to CouchDB, except that
if the C<_id> field does not start with C<_design/> it will be automatically added.

=back

=head1 AUTHOR

Robin Berjon, <robin @t berjon d.t com>

=head1 BUGS 

Please report any bugs or feature requests to bug-couchdb-deploy at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CouchDb-Deploy.

=head1 COPYRIGHT & LICENSE 

Copyright 2008 Robin Berjon, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as 
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may 
have available.

=cut
