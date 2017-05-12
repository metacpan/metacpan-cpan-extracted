package DB::CouchDB;

use warnings;
use strict;
use JSON -convert_blessed_universally;
use LWP::UserAgent;
use URI;
use Encode;

$DB::CouchDB::VERSION = 0.2;

=head1 NAME

    DB::CouchDB - A low level perl module for CouchDB

=head1 VERSION

0.2

=head1 RATIONALE

After working with a lot several of the CouchDB modules already in CPAN I found
myself dissatisfied with them. Since the API for Couch is so easy I wrote my own
which I find to have an API that better fits a CouchDB Workflow.

=head1 SYNOPSIS

    my $db = DB::CouchDB->new(host => $host,
                              db   => $dbname);
    my $doc = $db->get_doc($docname);
    my $docid = $doc->{_id};

    my $doc_iterator = $db->view('foo/bar', \%view_query_opts);

    while ( my $result = $doc_iterator->next() ) {
        ... #do whatever with the result the view returns
    }

=head1 METHODS

=head2 new(%dbopts)

This is the constructor for the DB::CouchDB object. It expects
a list of name value pairs for the options to the CouchDB database.

=over 4

=item *

Required options: (host => $hostname, db => $database_name);

=item *

Optional options: (port => $db_port)

=back

=cut

sub new{
    my $class = shift;
    my %opts = @_;
    $opts{port} = 5984
        if (!exists $opts{port});
    my $obj = {%opts};
    $obj->{json} = JSON->new();
    return bless $obj, $class; 
}

=head2 Accessors

=over 4

=item *

host - host name of db

=item *

db - database name

=item *

port - port number of the database server

=item *

json - the JSON object for serialization

=back

=cut

sub host {
    return shift->{host};
}

sub port {
    return shift->{port};
}

sub db {
    return shift->{db};
}

sub json {
    my $self = shift;
    return $self->{json};
}

=head2 handle_blessed

Turns on or off the JSON's handling of blessed objects.

    $db->handle_blessed(1) #turn on blessed object handling
    $db->handle_blessed() #turn off blessed object handling

=cut

sub handle_blessed {
    my $self = shift;
    my $set  = shift;

    my $json = $self->json();
    if ($set) {
        $json->allow_blessed(1);
        $json->convert_blessed(1);
    } else {
        $json->allow_blessed(0);
        $json->convert_blessed(0);
    }
    return $self;
}

=head2 all_dbs

    my $dbs = $db->all_dbs() #returns an arrayref of databases on this server

=cut

sub all_dbs {
    my $self = shift;
    my $args = shift; ## do we want to reduce the view?
    my $uri = $self->_uri_all_dbs();
    if ($args) {
        my $argstring = _valid_view_args($args);
        $uri->query($argstring);
    }
    return $self->_call(GET => $uri); 
}

=head2 all_docs

    my $dbs = $db->all_dbs() #returns a DB::CouchDB::Iterator of
                             #all documents in this database

=cut

sub all_docs {
    my $self = shift;
    my $args = shift;
    my $uri = $self->_uri_db_docs();
    if ($args) {
        my $argstring = _valid_view_args($args);
        $uri->query($argstring);
    }
    return DB::CouchDB::Iter->new($self->_call(GET => $uri));
}

=head2 db_info

    my $dbinfo = $db->db_info() #returns a DB::CouchDB::Result with the db info

=cut

sub db_info {
    my $self = shift;
    return DB::CouchDB::Result->new($self->_call(GET => $self->_uri_db()));
}

=head2 create_db

Creates the database in the CouchDB server.

    my $result = $db->create_db() #returns a DB::CouchDB::Result object

=cut

sub create_db {
    my $self = shift;
    return DB::CouchDB::Result->new($self->_call(PUT => $self->_uri_db()));
}

=head2 delete_db

deletes the database in the CouchDB server

    my $result = $db->delete_db() #returns a DB::CouchDB::Result object

=cut

sub delete_db {
    my $self = shift;
    return DB::CouchDB::Result->new($self->_call(DELETE => $self->_uri_db()));
}

=head2 create_doc

creates a doc in the database. The document will have an automatically assigned
id/name.

    my $result = $db->create_doc($doc) #returns a DB::CouchDB::Result object

=cut

sub create_doc {
    my $self = shift;
    my $doc = shift;
    my $jdoc = $self->json()->encode($doc);
    return DB::CouchDB::Result->new(
        $self->_call(POST => $self->_uri_db(), $jdoc)
    );
}

=head2 temp_view

runs a temporary view.

    my $results = $db->temp_view($view_object);

=cut

sub temp_view {
    my $self = shift;
    my $doc = shift;
    my $jdoc = $self->json()->encode($doc);
    return DB::CouchDB::Iter->new(
        $self->_call(POST => $self->uri_db_temp_view(), $jdoc)
    );
}

=head2 create_named_doc

creates a doc in the database, the document will have the id/name you specified

    my $result = $db->create_named_doc($doc, $docname) #returns a DB::CouchDB::Result object

=cut

#TODO this really needs to have the same API as all the others. $name first then $doc
sub create_named_doc {
    my $self = shift;
    my $doc = shift;
    my $name = shift;
    my $jdoc = $self->json()->encode($doc);
    return DB::CouchDB::Result->new($self->_call(PUT => $self->_uri_db_doc($name), $jdoc));
}

=head2 update_doc

Updates a doc in the database.

    my $result = $db->update_doc($docname, $doc) #returns a DB::CouchDB::Result object

=cut

sub update_doc {
    my $self = shift;
    my $name = shift;
    my $doc  = shift;
    my $jdoc = $self->json()->encode($doc);
    return DB::CouchDB::Result->new($self->_call(PUT => $self->_uri_db_doc($name), $jdoc));
}

=head2 delete_doc

Deletes a doc in the database. you must supply a rev parameter to represent the
revision of the doc you are updating. If the revision is not the current revision 
of the doc the update will fail.

    my $result = $db->delete_doc($docname, $rev) #returns a DB::CouchDB::Result object

=cut

sub delete_doc {
    my $self = shift;
    my $doc = shift;
    my $rev = shift;
    my $uri = $self->_uri_db_doc($doc);
    $uri->query('rev='.$rev);
    return DB::CouchDB::Result->new($self->_call(DELETE => $uri));
}

=head2 get_doc

Gets a doc in the database.

    my $result = $db->get_doc($docname) #returns a DB::CouchDB::Result object

=cut

sub get_doc {
    my $self = shift;
    my $doc = shift;
    return DB::CouchDB::Result->new($self->_call(GET => $self->_uri_db_doc($doc)));
}

=head2 view

Returns a views results from the database.

    my $rs = $db->view($viewname, \%view_args) #returns a DB::CouchDB::Iter object

=head3 A note about view args:

the view args allow you to constrain and/or window the results that the 
view gives back. Some of the ones you will probably want to use are:

    group => "true"      #turn on the reduce portion of your view
    key   => '"keyname"' # only gives back results with a certain key
    
    #only return results starting at startkey and goint up to endkey
    startkey => '"startkey"',
    endkey   => '"endkey"'

    count => $num  #only returns $num rows
    offset => $num #return starting from $num row

All the values should be valid json encoded.
See http://wiki.apache.org/couchdb/HttpViewApi for more information on the view
parameters

=cut

## TODO: still need to handle windowing on views
sub view {
    my $self = shift;
    my $view = shift;
    my $args = shift; ## do we want to reduce the view?
    my $uri = $self->_uri_db_view($view);
    if ($args) {
        my $argstring = _valid_view_args($args);
        $uri->query($argstring);
    }
    return DB::CouchDB::Iter->new($self->_call(GET => $uri));
}

sub _valid_view_args {
    my $args = shift;
    my $string;
    my @str_parts = map {"$_=$args->{$_}"} keys %$args;
    $string = join('&', @str_parts);

    return $string;
}

sub uri {
    my $self = shift;
    my $u = URI->new();
    $u->scheme("http");
    $u->host($self->{host}.':'.$self->{port});
    return $u;
}

sub _uri_all_dbs {
    my $self = shift;
    my $uri = $self->uri();
    $uri->path('/_all_dbs');
    return $uri;
}

sub _uri_db {
    my $self = shift;
    my $db = $self->{db};
    my $uri = $self->uri();
    $uri->path('/'.$db);
    return $uri;
}

sub _uri_db_docs {
    my $self = shift;
    my $db = $self->{db};
    my $uri = $self->uri();
    $uri->path('/'.$db.'/_all_docs');
    return $uri;
}

sub _uri_db_doc {
    my $self = shift;
    my $db = $self->{db};
    my $doc = shift;
    my $uri = $self->uri();
    $uri->path('/'.$db.'/'.$doc);
    return $uri;
}

sub _uri_db_bulk_doc {
    my $self = shift;
    my $db = $self->{db};
    my $uri = $self->uri();
    $uri->path('/'.$db.'/_bulk_docs');
    return $uri;
}

sub _uri_db_view {
    my $self = shift;
    my $db = $self->{db};
    my $view = shift;
    my $uri = $self->uri();
    $uri->path('/'.$db.'/_view/'.$view);
    return $uri;
}

sub uri_db_temp_view {
    my $self = shift;
    my $db = $self->{db};
    my $uri = $self->uri();
    $uri->path('/'.$db.'/_temp_view');
    return $uri;

}

sub _call {
    my $self    = shift;
    my $method  = shift;
    my $uri     = shift;
    my $content = shift;
    
    my $req     = HTTP::Request->new($method, $uri);
    $req->content(Encode::encode('utf8', $content));
         
    my $ua = LWP::UserAgent->new();
    my $return = $ua->request($req);
    my $response = $return->decoded_content({
		default_charset => 'utf8'
    });
    my $decoded;
    eval {
        $decoded = $self->json()->decode($response);
    };
    if ($@) {
        return {error => $return->code, reason => $response}; 
    }
    return $decoded;
}

package DB::CouchDB::Iter;

sub new {
    my $self = shift;
    my $results = shift;
    my $rows = $results->{rows};
    
    return bless { data => $rows,
                   count => $results->{total_rows},
                   offset => $results->{offset},
                   iter => mk_iter($rows),
                   iter_key => mk_iter($rows, 'key'),
                   error => $results->{error},
                   reason => $results->{reason},
                 }, $self;
}

sub count {
    return shift->{count};
}

sub offset {
    return shift->{offset};
}

sub data {
    return shift->{data};
}

sub err {
    return shift->{error};
}

sub errstr {
    return shift->{reason};
}

sub next {
   my $self = shift;
   return $self->{iter}->(); 
}

sub next_key {
    my $self = shift;
   return $self->{iter_key}->(); 
}

sub next_for_key {
    my $self = shift;
    my $key = shift;
    my $ph = $key."_iter";
    if (! defined $self->{$ph} ) {
        my $iter = mk_iter($self->{data}, 'value', sub {
            my $item = shift;
            return $item 
                if $item->{key} eq $key;
            return;
        });
        $self->{$ph} = $iter;
    }
    return $self->{$ph}->();
}

sub mk_iter {
    my $rows = shift;
    my $key = shift || 'value';
    my $filter = shift || sub { return $_ };
    my $mapper = sub {
        my $row = shift;
        return @{ $row->{$key} }
            if ref($row->{$key}) eq 'ARRAY';
        return $row->{$key};
    };
    my @list = map { $mapper->($_) } grep { $filter->($_) } @$rows;
    my $index = 0;
    return sub {
        return if $index > $#list;
        my $row = $list[$index];
        $index++;
        return $row;
    };
}

package DB::CouchDB::Result;

sub new {
    my $self = shift;
    my $result = shift;
    
    return bless $result, $self;
}

sub err {
    return shift->{error};
}

sub errstr {
    return shift->{reason};
}

=head1 AUTHOR

Jeremy Wall <jeremy@marzhillstudios.com>

=head1 DEPENDENCIES

=over 4

=item *

L<LWP::UserAgent>

=item *

L<URI>

=item * 

L<JSON>

=back

=head1 SEE ALSO

=over 4 

=item *

L<DB::CouchDB::Result> - POD for the DB::CouchDB::Result object

=item *

L<DB::CouchDB::Iter> - POD for the DB::CouchDB::Iter object

=item *

L<DB::CouchDB::Schema> - higher level wrapper with some schema handling functionality

=back

=cut

1;
