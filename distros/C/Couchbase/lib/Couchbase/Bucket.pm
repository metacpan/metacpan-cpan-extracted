package Couchbase::Bucket;

use strict;
use warnings;

use JSON::MaybeXS;
use URI;
use Storable;

use Couchbase::Core;
use Couchbase::_GlueConstants;
use Couchbase::Document;
use Couchbase::Settings;
use Couchbase::OpContext;
use Couchbase::View::Handle;
use Couchbase::HTTPDocument;
use Couchbase::N1QL::Handle;

my $_JSON = JSON::MaybeXS->new()->allow_nonref;
sub _js_encode { $_JSON->encode($_[0]) }
sub _js_decode { $_JSON->decode($_[0]) }

sub new {
    my ($pkg, $connstr, $opts) = @_;
    my %options = ($opts ? %$opts : ());

    if (ref $connstr eq 'HASH') {
        %options = (%options, %$connstr);
    } else {
        $options{connstr} = $connstr;
    }

    die "Must have connection string" unless $options{connstr};
    my $noconn = delete $options{no_init_connect};
    my $self = $pkg->construct(\%options);
    $self->connect() unless $noconn;

    $self->_encoder(CONVERTERS_JSON, \&_js_encode);
    $self->_decoder(CONVERTERS_JSON, \&_js_decode);
    $self->_encoder(CONVERTERS_STORABLE, \&Storable::freeze);
    $self->_decoder(CONVERTERS_STORABLE, \&Storable::thaw);
    return $self;
}

sub __statshelper {
    my ($doc, $server, $key, $value) = @_;
    if (!$doc->value || ref $doc->value ne 'HASH') {
        $doc->value({});
    }
    ($doc->value->{$server} ||= {})->{$key} = $value;
}

sub __obshelper {
    my ($doc,$status,$cas,$ismaster) = @_;
    my $obj = {
        status => $status,
        cas => $cas,
        master=> $ismaster
    };
    if (ref $doc->value ne 'ARRAY') {
        $doc->value([$obj]);
    } else {
        push @{$doc->value}, $obj;
    }
}

sub _dispatch_stats {
    my ($self, $mname, $key, $options, $ctx) = @_;
    my $doc;

    if (ref $key eq 'Couchbase::Document') {
        $doc = $key;
    } else {
        $doc = Couchbase::Document->new($key || "");
    }

    {
        no strict 'refs';
        $self->$mname($doc, $options, $ctx);
    }

    return $doc;
}

sub stats {
    my ($self, @args) = @_;
    $self->_dispatch_stats("_stats", @args);
}

sub keystats {
    my ($self, @args) = @_;
    $self->_dispatch_stats("_keystats", @args);
}

sub observe {
    my ($self,$doc,@args) = @_;

    my $newdoc = Couchbase::Document->new($doc);
    $newdoc->_cas(0);
    $newdoc->expiry(0);
    $self->_observe($newdoc,@args);
    return $newdoc;
}

sub transform {
    my ($self, $doc, $xfrm) = @_;
    my $tmo = $self->settings()->{operation_timeout} / 1_000_000;
    my $now = time();
    my $end = $now + $tmo;

    while ($now < $end) {
        # Try to perform the mutation
        my $rv = $xfrm->(\$doc->value);

        if (!$rv) {
            last;
        }

        $self->replace($doc);

        if ($doc->is_cas_mismatch) {
            $self->get($doc);
        } else {
            last;
        }
    }

    return $doc;
}

sub transform_id {
    my ($self, $id, $xfrm) = @_;
    my $doc = Couchbase::Document->new($id);
    $self->get($doc);
    return $self->transform($doc, $xfrm);
}

sub settings {
    my $self = shift;
    tie my %h, 'Couchbase::Settings', $self;
    return \%h;
}

sub fetch {
    my ($self, $id) = @_;
    my $doc = Couchbase::Document->new($id);
    $self->get($doc);
    return $doc;
}

sub _htraw {
    my ($self,$method,$path,$options) = @_;
    $options ||= {};
    $method = uc($method);

    my $methmap = {
        'GET' => LCB_HTTP_METHOD_GET,
        'POST' => LCB_HTTP_METHOD_POST,
        'PUT' => LCB_HTTP_METHOD_PUT,
        'DELETE' => LCB_HTTP_METHOD_DELETE
    };

    my $methnum = $methmap->{$method};
    if (!defined($methnum)) {
        die("Unknown method $method");
    }

    $options->{method} = $methnum;
    my $htd = Couchbase::HTTPDocument->new($path);
    $self->_http($htd, $options);
    return $htd;
}

# Gets a design document
sub design_get {
    my ($self,$path) = @_;
    return $self->_htraw('GET', '_design/'.$path);
}

# saves a design document
sub design_put {
    my ($self,$design,$path) = @_;
    if (ref $design) {
        $path = $design->{_id};
        $design = encode_json($design);
    }
    if (!$path) {
        die("Cannot determine path for design document");
    }

    return $self->_htraw('PUT', $path, {
        body => $design,
        content_type => 'application/json'
    });
}

sub view_iterator {
    my ($self,$viewpath,%options) = @_;
    my $iter = Couchbase::View::Handle->new($self, $viewpath, %options);
    return $iter;
}

sub view_slurp {
    my $self = shift;
    my $iter = $self->view_iterator(@_);
    $iter->slurp();
    return $iter;
}

sub query_iterator {
    my ($self, $query, $params, $options) = @_;
    my $iter = Couchbase::N1QL::Handle->new($self, $query, $params, $options);
    return $iter;
}

sub query_slurp {
    my $self = shift;
    my $iter = $self->query_iterator(@_);
    $iter->slurp();
    return $iter;
}

sub bucket {
    shift->settings->{bucket};
}

1;

__END__

=head1 NAME


Couchbase::Bucket - Couchbase Cluster data access


=head1 SYNOPSIS


    # Imports
    use Couchbase::Bucket;
    use Couchbase::Document;

    # Create a new connection
    my $cb = Couchbase::Bucket->new("couchbases://anynode/bucket", { password => "secret" });

    # Create and store a document
    my $doc = Couchbase::Document->new("idstring", { json => ["encodable", "string"] });
    $cb->insert($doc);
    if (!$doc->is_ok) {
        warn("Couldn't store document: " . $doc->errstr);
    }

    # Retrieve a document:
    $doc = Couchbase::Document->new("user:mnunberg");
    $cb->get($doc);
    printf("Full name is %s\n", $doc->value->{name});

    # Query a view:
    my $res = Couchbase::Document->view_slurp(['design_name', 'view_name'], limit => 10);
    # $res is actually a subclass of Couchbase::Document
    if (! $res->is_ok) {
        warn("There was an error in querying the view: ".$res->errstr);
    }
    foreach my $row (@{$res->rows}) {
        printf("Key: %s. Document ID: %s. Value: %s\n", $row->key, $row->id, $row->value);
    }

    # Get multiple items at once
    my $batch = $cb->batch;
    $batch->get(Couchbase::Document->new("user:$_")) for (qw(foo bar baz));

    while (($doc = $batch->wait_one)) {
        if ($doc->is_ok) {
            printf("Real name for userid '%s': %s\n", $doc->id, $doc->value->{name});
        } else {
            warn("Couldn't get document '%s': %s\n", $doc->id, $doc->errstr);
        }
    }


=head1 DESCRIPTION

Couchbase::Bucket is the main module for L<Couchbase> and represents a data
connection to the cluster.

The usage model revolves around an L<Couchbase::Document> which is updated
for each operation. Normally you will create a L<Couchbase::Document> and
populate it with the relevant fields for the operation, and then perform
the operation itself. When the operation has been completed the relevant
fields become updated to reflect the latest results.


=head2 CONNECTING


=head3 Connection String

To connect to the cluster, specify a URI-like I<connection string>. The connection
string is in the format of C<SCHEME://HOST1,HOST2,HOST3/BUCKET?OPTION=VALUE&OPTION=VALUE>

=over

=item scheme

This will normally be C<couchbase://>. For SSL connections, use C<couchbases://>
(note the extra I<s> at the end). See L</"Using SSL"> for more details


=item host

This can be a single host or a list of hosts. Specifying multiple hosts is not
required but may increase availability if the first node is down. Multiple hosts
should be separated by a comma.

If your administrator has configured the cluster to use non-default ports then you
may specify those ports using the form C<host:port>, where C<port> is the I<memcached>
port that the given node is listening on. In the case of SSL this should be the
SSL-enabled I<memcached> port.


=item bucket


This is the data bucket you wish to connect to. If left unspecified, it will revert
to the C<default> bucket.


=item options

There are several options which can modify connection and general settings for the
newly created bucket object. Some of these may be modifiable via L<Couchbase::Settings>
(returned via the C<settings()> method) as well. This list only mentions those
settings which are specific to the initial connection


=over

=item C<config_total_timeout>

Specify the maximum amount of time (in seconds) to wait until the client has
been connected.


=item C<config_node_timeout>

Specify the maximum amount of time (in seconds) to wait for a given node to
respond to the initial connection request. This number may also not be higher
than the value for C<config_total_timeout>.


=item C<certpath>

If using SSL, this option must be specified and should contain the local path
to the copy of the cluster's SSL certificate. The path should also be URI-encoded.


=back

=back


=head3 Using SSL


To connect to an SSL-enabled cluster, specify the C<couchbases://> for the scheme.
Additionally, ensure that the C<certpath> option contains the correct path, for example:


    my $cb = Couchbase::Bucket->new("couchbases://securehost/securebkt?certpath=/var/cbcert.pem");


=head3 Specifying Bucket Credentials

Often, the bucket will be password protected. You can specify the password using the
C<password> option in the C<$options> hashref in the constructor.


=head3 new($connstr, $options)


Create a new connection to a bucket. C<$connstr> is a L<"Connection String"> and
C<$options> is a hashref of options. The only recognized option key is C<password>
which is the bucket password, if applicable.

This method will attempt to connect to the cluster, and die if a connection could
not be made.


=head2 DATA ACCESS


Data access methods operate on an L<Couchbase::Document> object. When the operation
has completed, its status is stored in the document's C<errnum> field (you can also
use the C<is_ok> method to check if no errors occurred).


=head3 get($doc)

=head3 get_and_touch($doc)


Retrieve a document from the cluster. C<$doc> is an L<Couchbase::Document>. If the
operation is successful, the value of the item will be accessible via its C<value>
field.


    my $doc = Couchbase::Document->new("id_to_retrieve");
    $cb->get($doc);
    if ($doc->is_ok) {
        printf("Got value: %s\n", $doc->value);
    }


The C<get_and_touch> variant will also update (or clear) the expiration time of
the item. See L<"Document Expiration"> for more details:

    my $doc = Couchbase::Document->new("id", { expiry => 300 });
    $cb->get_and_touch($doc); # Expires in 5 minutes


=head3 fetch($id)

This is a convenience method which will create a new document with the given C<id>
and perform a C<get> on it. It will then return the resulting document.

    my $doc = $cb->fetch("id_to_retrieve");


=head3 insert($doc)

=head3 replace($doc, $options)

=head3 upsert($doc, $options)


    my $doc = Couchbase::Document->new(
        "mutation_method_names",
        [ "insert", "replace", "upsert"],
        { expiry => 3600 }
    );

    # Store a new item into the cluster, failing if it exists:
    $cb->insert($doc);

    # Unconditionally overwrite the value:
    $cb->upsert($doc);

    # Only replace an existing value
    $cb->replace($doc);

    # Ignore any kind of race conditions:
    $cb->replace($doc, { ignore_cas => 1 });

    # Store the document, wait until it has been persisted
    # on at least 2 nodes
    $cb->replace($doc, { persist_to => 2 });


These three methods will set the value of the document on the server. C<insert>
will only succeed if the item does B<not> exist, C<replace> will only succeed if the
item B<already> exists, and C<upsert> will unconditionally write the new value
regardless of it existing or not.


=head4 Storage Format

By default, the document is serialized and stored as JSON. This allows proper
integration with other optional functionality of the cluster (such as views and
N1QL queries). You may also store items in other formats which may then be
transparently serialized and deserialized as needed.

To specify the storage format for a document, specify the `format` setting
in the L<Couchbase::Document> object, like so:

    use Couchbase::Document;
    my $doc = Couchbase::Document->new('foo', \1234, { format => COUCHBASE_FMT_STORABLE);


This version of the client uses so-called "Common Flags", allowing seamless integration
with Couchbase clients written in other languages.


=head4 Encoding Formats

Bear in mind that Perl's default encoding is I<Latin-1> and not I<UTF-8>. To
that effect, any input, unless indicated otherwise, is assumed to thus be
Latin-1. There are various ways to change the "type" of a string, the details
of which can be found within the L<utf8> and L<Encode> modules.

From the perspective of this module, any I<input> string which is marked
as being JSON or UTF8 will be marked as being UTF-8. This may mean some
smaller performance implications. If this is a concern, you can intercept
the JSON decoding function and handle the raw string there.


=head4 CAS Operations

To avoid race conditions when two applications attempt to write to the same document
Couchbase utilizes something called a I<CAS> value which represents the last known
state of the document. This I<CAS> value is modified each time a change is made to the
document, and is returned back to the client for each operation. If the C<$doc> item is
a document previously used for a successful C<get> or other operation, it will contain
the I<CAS>, and the client will send it back to the server. If the current I<CAS> of the
document on the server does not match the value embedded into the document the operation
will fail with the code C<COUCHBASE_KEY_EEXISTS>.

To always modify the value (ignoring whether the value may have been previously
modified by another application), set the C<ignore_cas> option to a true value in
the C<$options> hashref.


=head4 Durability Requirements

Mutation operations in couchbase are considered successful once they are stored
in the master node's cache for a given key. Sometimes extra redundancy and
reliability is required, where an application should only proceed once the data
has been replicated to a certain number of nodes and possibly persisted to their
disks. Use the C<persist_to> and C<replicate_to> options to specify the specific
durability requirements:

=over

=item C<persist_to>

Wait until the item has been persisted (written to non-volatile storage) of this
many nodes. A value of I<1> means the master node, where a value of 2 or higher
means the master node I<and> C<n-1> replica nodes.


=item C<replicate_to>

Wait until the item has been replicated to the RAM of this many replica nodes.
Your bucket must have at least this many replicas configured B<and> online for
this option to function.

=back

You may specify a I<negative> value for either C<persist_to> or C<replicate_to>
to indicate that a "best-effort" behavior is desired, meaning that replication
and persistence should take effect on as many nodes as are currently online,
which may be less than the number of replicas the bucket was configured with.

You may request replication without persistence by simply setting C<replicate_to=0>.


=head4 Document Expiration

In many use cases it may be desirable to have the document automatically
deleted after a certain period of time has elapsed (think about session management).
You can specify when the document should be deleted, either as an offset from now
in seconds (up to 30 days), or as Unix timestamp.

The expiration is considered a property of the document and is thus configurable
via the L<Couchbase::Document>'s C<expiry> method.


=head3 remove($doc, $options)

Remove an item from the cluster. The operation will fail if the item does not exist,
or if the item's L<CAS|"CAS Operations"> has been modified.

    my $doc = Couchbase::Document->new("KILL ME PLEASE");
    $cb->remove($doc);
    if ($doc->is_ok) {
        print "Deleted document OK!\n";
    } elsif ($doc->is_not_found) {
        print "Document already deleted!\n"
    } elseif ($doc->is_cas_mismatch) {
        print "Someone modified our document before we tried to delete it!\n";
    }


=head3 touch($doc, $options)

Update the item's expiration time. This is more efficient than L<get_and_touch> as it
does not return the item's value across the network.


=head2 Client Settings


=head3 settings()

Returns a hashref of settings (see L<Couchbase::Settings>). Because this is a hashref,
its values may be C<local>ized.


Set a high timeout for a specified operation:

    {
        local $cb->settings->{operation_timeout} = 20; # 20 seconds
        $cb->get($doc);
    }




=head2 ADVANCED DATA ACCESS


=head3 counter($doc, { delta=>n1, initial=n2 })


    sub example_hit_counter {
        my $page_name = shift;
        my $doc = Couchbase::Document->new("page:$page_name");
        $cb->counter($doc, { initial => 1, delta => 1 });
    }



This method treats the stored value as a number (i.e. a string which can
be parsed as a number, such as C<"42">) and atomically modifies its value
based on the parameters passed.


The options are:

=over

=item C<delta>

the amount by which the current value should be modified. If the value for this option
is I<negative> then the counter will be decremented


=item C<initial>

The initial value to assign to the item on the server if it does not yet exist.
If this option is not specified and the item on the server does not exist then
the operation will fail.


=back


=head3 append_bytes($doc, { fragment => "string" })

=head3 prepend_bytes($doc, { fragment => "string"} )

These two methods concatenate the C<fragment> value and the existing value on
the server. They are equivalent to doing the following:



    # Append:
    $doc->value($doc->value . '_suffix');
    $doc->format('utf8');
    $cb->replace($doc);

    # Prepend:
    $doc->value('prefix_' . $doc->value);
    $doc->format('utf8');
    $cb->replace($doc);


The C<fragment> option I<must> be specified, and the value is I<not> updated
in the original document.

Also note that these methods do a raw I<string-based> concatenation, and
will thus only produce desired results if the existing value is a plain
string. This is in contrast to C<COUCHBASE_FMT_JSON> where a string
is stored enclosed in quotation marks.

Thus a JSON string may be stored as C<"foo">, and appending to it
will yield C<"foo"bar>, which is typically not what you want.


=head2 BATCH OPERATIONS

Batch operations allow more efficient utilization of the network
by reducing latency and increasing the number of commands
sent at a single time to the server.

Batch operations are executed by creating an L<Couchbase::OpContext>;
associating commands with the conext, and waiting for the
commands to complete.


To create a new context, use the C<batch> method


=head3 batch()

Returns a new L<Couchbase::OpContext> which may be used to schedule
operations.


=head2 Batched Durability Requirements

In some scenarios it may be more efficient on the network to
submit durability requirement requests as a large single command. The behavior for
the C<persist_to> and C<replicate_to> parameters in the C<upsert()> family of
methods will cause a durability request to be sent out to the given nodes
node as soon as the success is received for the newly-modified item. This
approach reduces latency at the cost of additional bandwidth.

Some bandwidth may be potentially saved if these requests are all batched
together:


=head2 durability_batch($options)

I<Volatile - Subject to change>

Creates a new durability batch. A durability batch is a special kind of batch
where the contained commands can only be documents whose durability is to
be checked.

    my $batch;
    $batch = $cb->batch;
    $batch->upsert($_) for @docs;
    $batch->wait_all;

    $batch = $cb->durability_batch({ persist_to => 1, replicate_to => 2 });
    $batch->endure($_) for @docs;
    $batch->wait_all;


The C<options> passed can be C<persist_to> and C<replicate_to>. See the
L<"Durability Requirements"> section for information.


=head2 N1QL QUERIES (EXPERIMENTAL)


N1QL queries are available as an experimental feature of the client
library.

The N1QL API exposes two functions, both of which function
similarly to their view counterparts.

At the time of writing, the server does not include N1QL as an integrated
feature (because it is still experimental). This means it must be downloaded
as a standalone package
(see L<http://docs.couchbase.com/developer/n1ql-dp4/n1ql-intro.html>). Once
downloaded and configured, the C<_host> option should be passed to the
query function (as detailed below).

N1QL functions return a L<Couchbase::N1QL::Handle> object, which functions
similarly to L<Couchbase::View::Handle> (internally, they share a lot of
code).


=head3 query_slurp("query", $queryargs, $queryopts)

Issue an N1QL query. This will send the query to the server (encoding
any parameters as needed).

    my $rv = $cb->query_slurp(
        # Query string
        'SELECT *, META().id FROM travel WHERE travel.country = $country ',

        # Placeholder values
        { country => "Ecuador", },

        # Query options
        { _host => "localhost:8093" }
    );

    foreach my $row (@{$rv->rows}) {
        # do something with decoded JSON
    }


The C<queryargs> parameter can either be a hashref of named placeholders
(omiting of course, the leading C<$> which is handled internally), or it can
be an arrayref of positional placeholders (if your query uses positional
placeholders).

The C<queryopts> is a set of other modifiers for the query. Most of these
are sent to the server. One special parameter is the C<_host> parameter, which
points to a standalone instance of the N1QL Developer Preview installation;
a temporary necesity for pre-release versions. Using of the C<_host> paramter
will be removed once Couchbase Server is available (in release or pre-release)
with an integrated N1QL process.


=head3 query_iterator("query", $queryargs, $queryopts)

This function is to C<query_slurp> as C<view_iterator> is to C<view_slurp>.
In short, this allows an iterator over the rows, only fetching data from
the network as needed. This is more efficient (but a bit less simple to
use) than C<query_slurp>

    my $rv = $cb->query_iterator("select * from default");
    while ((my $row = $rv->next)) {
        # do something with row.
    }


=head2 VIEW (MAPREDUCE) QUERIES


View methods come in two flavors. One is an iterator which incrementally
fetches data from the network, while the other loads the entire data and
then returns. For small queries (i.e. those which do not return many
results), which API you use is a matter of personal preference. For larger
resultsets, however, it often becomes a necessity to not load the entire
dataset into RAM.

Both the C<view_slurp> and C<view_iterator> return L<Couchbase::View::Handle>
objects. This has been changed from previous versions which returned a
C<Couchbase::View::HandleInfo> object (Though the APIs remain the same).


=head3 view_slurp("design/view", %options)

Queries and returns the results of a view. The first argument may be provided
either as a string of C<"$design/$view"> or as a two-element array reference
containing the design and view respectively.

The C<%options> are options passed verbatim to the view engine. Some options
however are intercepted by the client, and modify how the view is queried.

=over

=item C<spatial>

Indicate that the queried view is a geospatial view. This is required since the
formatting of the internal URI is slightly different.

=item C<include_docs>

Indicate that the relevant documents should be fetched for each view. The
following forms are equivalent.

    # fetching directly:
    my $iter = $bkt->view_iterator(['design', 'view']);
    while ((my $row = $iter->next)) {
        my $doc = Couchbase::Document->new($row->id);
        $bkt->get($doc);
    }

    # using include_docs
    my $iter = $bkt->view_iterator(['design', 'view'], include_docs => 1);
    while ((my $row = $iter->next)) {
        my $doc = $row->doc;
    }

Using C<include_docs> is significantly more efficient than fetching the rows
manually as it allows the library to issue gets in bulk for each raw chunk
of view results received - and also allows the library to "lazily" fetch
documents while other rows are being received.

=back

The returned object contains various status information about the query. The
rows themselves may be found inside the C<rows> accessor:

    my $rv = $cb->view_slurp("beer/brewery_beers", limit => 5);
    foreach my $row @{ $rv->rows } {
        printf("Got row for key %s with document id %s\n", $row->key, $row->id);
    }


This method returns an instance of L<Couchbase::View::Handle> which may be used
to inspect for error messages. The object is in fact a subclass of
L<Couchbase::Document> with an additional C<errinfo> method to provide more
details about the operation.

    if (!$rv->is_ok) {
        if ($rv->errnum) {
            # handle error code
        }
        if ($rv->http_code !~ /^2/) {
            # Failed HTTP status
        }
    }

As of version 2.0.3, this method is implemented as a wrapper atop C<view_iterator>


=head3 view_iterator("design/view", %options)

This works in much the same way as the C<view_slurp()> method does, except
that it returns responses incrementally, which is handy if you expect the
query to return a large amount of results:


    my $iter = $cb->view_iterator("beer/brewery_beers");
    while (my $row = $iter->next) {
        printf("Got row for key %s with document id %s\n", $row->key, $row->id);
    }


Note that the contents of the C<Handle> object are only considered valid once
the iterator has been through at least I<one> iteration; thus:

B<Incorrect>, because it requests the C<info> object before iteration has
started

    my $iter = $cb->view_iterator($dpath);
    if (!$iter->info->is_ok) {
        # ...
    }

B<Correct>

    my $iter = $cb->view_iterator($dpath);
    while (my $row = $iter->next) {
        # ...
    }
    if (!$iter->info->is_ok) {
        # ...
    }


=head2 INFORMATIONAL METHODS

These methods return various sorts of into about the cluster or specific
items


=head3 stats()

=head3 stats("spec")

Retrieves cluster statistics from each server. The return value
is an L<Couchbase::Document> with its C<value> field containing a hashref
of hashrefs, like so:

    # Dump all the stats, per server:
    my $results = $cb->stats()->value;
    while (my ($server,$stats) = each %$results) {
        while (my ($statkey, $statval) = each %$stats) {
            printf("Server %s: %s=%s\n", $server, $statkey, $statval);
        }
    }


=head3 keystats($id)

Returns metadata about a specific document ID. The metadata is returned
in the same manner as in the C<stats()> method. This will solicit each server
which is either a master or replica for the item to respond with information
such as the I<cas>, I<expiration time>, and I<persistence state> of the item.

This method should be used for informative purposes only, as its output
and availability may change in the future.


=head3 observe($id, $options)

Returns persistence and replication status about a specific document ID.
Unlike the C<keystats> method, the information is received from the network
as binary and is thus more efficient.

You may also pass a C<master_only> option in the options hashref, in which
case only the master node from the item will be contacted.

