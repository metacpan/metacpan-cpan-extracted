package DB::CouchDB::Schema;
use DB::CouchDB;
use Moose;
use Carp;

our $VERSION = '0.3.04';

=head1 NAME

    DB::CouchDB::Schema - A Schema driven CouchDB module

=head1 VERSION

0.3.01

=head1 RATIONALE

After working with several of the CouchDB modules already in CPAN I found
myself dissatisfied with them. DB::CouchDB::Schema is intended to approach the
CouchDB Workflow from the standpoint of the schema. It provides tools for dumping
and restoring the views that define your schema and for querying the views in your
schema easily.

=head1 METHODS

=head2 new(%opts)

    my $schema = DB::CouchDB::Schema->new(host => $hostname,
                                          port => $db_port, # optional defaults to 5984
                                          db   => $databse_name);

Constructor for a CouchDB Schema.

=cut

has server => ( is => 'rw', isa => 'DB::CouchDB');
has schema => ( is => 'rw', isa => 'ArrayRef');
has views  => ( is => 'rw', isa => 'HashRef[Code]',
                required => 1, default => sub { {} } );

sub BUILD {
    my $self = shift;
    my $params = shift;
    if (keys %$params) {
        my $db = DB::CouchDB->new(%$params);
        $db->handle_blessed(1);
        $self->server($db);
        $self->load_schema_from_db();
    }
}

=head2 load_schema_from_script($script)

loads a CouchDB Schema from a json script file. This is sort of like the DDL
in a SQL DB only its essentially just a list of _design/* documents for the CouchDB

=cut

sub load_schema_from_script {
    my $self = shift;
    my $script = shift;
    $self->schema($self->server->json->decode($script));
    return $self;
}

=head2 load_schema_from_db()

Loads a CouchDB Schema from the Database on the server. this can later be dumped
to a file and pushed to a database using load_schema_from_script.

This method gets called for you during object construction so that you will have
a current look at the CouchDB Schema stored in your object.

=cut

sub load_schema_from_db {
    my $self = shift;
    my $db = $self->server;
    #load our schema
    my $doc_list = $self->get_views();
    my @schema;
    while (my $docname = $doc_list->next_key() ) {
        my $doc = $db->get_doc($docname);
        $self->_mk_view_accessor($doc);
        push @schema, $doc;
    }
    $self->schema(\@schema);
    return $self;
}

=head2 get_views()

Returns a List of all the views in the database;

=cut

sub get_views {
    my $self = shift;
    my $db = $self->server;
    #load our schema
    return $db->all_docs({startkey => '"_design/"',
                                  endkey   => '"_design/ZZZZZ"'});
}

=head2 dump_db

dumps the entire db to a file for backup

=cut

#TODO(jwall) tool to dump the whole db to a backup file
sub dump_whole_db {
    my $self = shift;
    my $pretty = shift;
    my $db = $self->server;
    #load our schema
    my $doc_list = $db->all_docs();
    my @docs;
    while (my $docname = $doc_list->next_key() ) {
        my $doc = $db->get_doc($docname);
        push @docs, $doc;
    }
    $db->json->pretty([$pretty]);
    my $script = $db->json->encode(\@docs);
    $db->json->pretty([undef]);
    return $script;
}

sub _mk_view_accessor {
    my $self = shift;
    my $doc = shift;
    my $id = $doc->{_id};
    return unless $id =~  /^_design/;
    my ($design) = $id =~ /^_design\/(.+)/;
    my $views = $doc->{views};
    for my $view (keys %$views) {
        my $method = $design."_".$view;
        $self->views()->{$method} = sub {
                my $args = shift;
                return $self->server->view($design."/$view", $args);
            };

        #use Moose and Class::Mop to dynamically add our method
        __PACKAGE__->meta->add_method($method, sub {
                my $self = shift;
                my $args = shift;
                if ( $self->{views}{$method} ) {
                    return $self->{views}{$method}->($args);
                }
                croak "The view $id does not exist in this database";
            }
        );
    }
}

=head2 schema

Returns the database schema as an arrayref of _design/ docs serialized to perl
objects. You can update you schema by modifying this object if you know what
you are doing. Then push the modifications to your database.

=cut

sub _schema_no_revs {
    my $self = shift;
    my @schema;
    for my $doc (@{ $self->schema() }) {
        my %newdoc = %$doc;
        delete $newdoc{_rev};
        push @schema, \%newdoc;
    }
    return @schema;
}

=head2 dump($pretty)

Returns the database schema as a json string.
if $pretty is true then the dump will be pretty printed

=cut

sub dump {
    my $self = shift;
    my $pretty = shift;
    my $db = $self->server;
    $db->json->pretty([$pretty]);
    my @schema = $self->_schema_no_revs();
    my $script = $db->json->encode(\@schema);
    $db->json->pretty([undef]);
    return $script;
}


=head2 push()

Pushes the current schema stored in the object to the database. Used in combination with load_schema_from_script
you can restore or create databse schemas from a json defintion file.

=cut

sub push {
    my $self = shift;
    my $db = $self->server;
    for my $doc ( $self->_schema_no_revs() ) {
        $db->create_named_doc($doc, $doc->{_id});
    }
    $self->load_schema_from_db();
    return $self;
}

=head2 push_from_script

=cut

sub push_from_script {
    my $self = shift;
    my $script = shift;
    my $db = $self->server;
    my $docs = $db->json->decode($script);
    for my $doc ( @$docs ) {
        delete $doc->{_rev}
            if $doc->{_rev};
        $db->create_named_doc($doc, $doc->{_id});
    }
    $self->load_schema_from_db();
    return $self;
}

=head2 get($doc)

=cut

sub get {
    my $self = shift;
    my $name = shift;
    return $self->server->get_doc($name);
}

=head2 create_doc(%sargs) 

create a doc on the server. accepts the following arguments

    id => 'the name of the document' #optional if you want to let CouchDB name it for you
    doc => $object #not optional $object is the document to store in CouchDB

=cut

sub create_doc {
    my $self = shift;
    my %args = @_;
    my $db = $self->server;
    if ( $args{id} ) {
        my $id = $args{id};
        return $db->create_named_doc( $args{doc}, $args{id} );
    } else {
        return $db->create_doc( $args{doc} );
    }
}

=head2 create_new_db(db => 'database name')

create a new database in CouchDB and return a DB::CouchDB::Schema object for it.

It takes the following argument
   
   db => 'database name' # not optional the name of the database to create.

=cut

sub create_new_db {
    my $self = shift;
    my %args = @_;
    my $db = $self->server;
    if ( !$args{db} ) {
        croak "Must provide a DB to create";
    }
    #create a new DB::CouchDB object to represent the server
    my $srv = DB::CouchDB->new( host => $db->host,
                                port => $db->port,
                                db   => $args{db},
                              );
    # create the database
    my $result = $srv->create_db();
    if ( $result->err ) {
        croak "Failed to create the DB $args{db}:". $result->errstr;
    }
    #create a schema object for the databas and return ite
    my $schema = DB::CouchDB::Schema->new();
    $schema->server($srv);
    return $schema;
}

=head2 wipe

Wipes the schema from the database. Only deletes the views not data and
only deletes views it knows about from either of the load_schema_from_* methods.

=cut

sub wipe {
    my $self = shift;
    my $db = $self->server;
    my @schema = @{ $self->schema() };
    for my $doc (@schema) {
        $db->delete_doc($doc->{_id}, $doc->{_rev});
    }
}

=head1 ACCESSORS

When DB::CouchDB objects are new'ed up they create accessors for the views defined
in the Database. Calling $schema->view_name(\%view_args) will return you the data
for the views. See L<DB::CouchDB> view method for more information on the args for a view.
The view_name gets translated as follows:

    #for view _design/docs/all
    my $rs = $schema->docs_all({group => "true"});

=cut

1;
