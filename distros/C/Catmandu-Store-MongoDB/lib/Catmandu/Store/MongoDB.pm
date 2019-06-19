package Catmandu::Store::MongoDB;

use Catmandu::Sane;

our $VERSION = '0.0803';

use Moo;
use Catmandu::Store::MongoDB::Bag;
use MongoDB;
use namespace::clean;

with 'Catmandu::Store';
with 'Catmandu::Transactional';

has client        => (is => 'lazy');
has database_name => (is => 'ro', required => 1);
has database      => (is => 'lazy', handles => [qw(drop)]);
has session =>
    (is => 'rw', predicate => 1, clearer => 1, writer => 'set_session');

with 'Catmandu::Droppable';

sub _build_client {
    my $self = shift;
    my $args = delete $self->{_args};
    my $host = $self->{_args}->{host} // 'mongodb://localhost:27017';
    $self->log->debug("Build MongoClient for $host");
    my $client = MongoDB::MongoClient->new($args);
    return $client;
}

sub _build_database {
    my $self          = shift;
    my $database_name = $self->database_name;
    $self->log->debug("Build or get database $database_name");
    my $database = $self->client->get_database($database_name);
    return $database;
}

sub BUILD {
    my ($self, $args) = @_;

    $self->{_args} = {};
    for my $key (keys %$args) {
        next
            if $key eq 'client'
            || $key eq 'database_name'
            || $key eq 'database';
        $self->{_args}{$key} = $args->{$key};
    }
}

sub transaction {
    my ($self, $sub) = @_;

    if ($self->has_session) {
        return $sub->();
    }

    my $session = $self->client->start_session;
    my @res;

    eval {
        $self->set_session($session);
        $session->start_transaction;

        @res = $sub->();

        COMMIT: {
            eval {
                $session->commit_transaction;
                1;
            } // do {
                my $err = $@;
                if ($err->has_error_label("UnknownTransactionCommitResult")) {
                    redo COMMIT;
                }
                else {
                    die $err;
                }
            };
        }

        $self->clear_session;

        1;
    } // do {
        my $err = $@;
        $session->abort_transaction;
        $self->clear_session;
        die $err;
    };

    wantarray ? @res : $res[0];
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::MongoDB - A searchable store backed by MongoDB

=head1 SYNOPSIS

    # On the command line
    $ catmandu import -v JSON --multiline 1 to MongoDB --database_name bibliography --bag books < books.json
    $ catmandu export MongoDB --database_name bibliography --bag books to YAML
    $ catmandu count MongoDB --database_name bibliography --bag books --query '{"PublicationYear": "1937"}'

    # In perl
    use Catmandu::Store::MongoDB;

    my $store = Catmandu::Store::MongoDB->new(database_name => 'test');

    my $obj1 = $store->bag->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

    my $obj3 = $store->bag->get('test123');

    $store->bag->delete('test123');

    $store->bag->delete_all;

    # All bags are iterators
    $store->bag->each(sub { ... });
    $store->bag->take(10)->each(sub { ... });

    # Search
    my $hits = $store->bag->search(query => '{"name":"Patrick"}');
    my $hits = $store->bag->search(query => '{"name":"Patrick"}' , sort => { age => -1} );
    my $hits = $store->bag->search(query => {name => "Patrick"} , start => 0 , limit => 100);
    my $hits = $store->bag->search(query => {name => "Patrick"} , fields => {_id => 0, name => 1});

    my $next_page = $hits->next_page;
    my $hits = $store->bag->search(query => '{"name":"Patrick"}' , page => $next_page);

    my $iterator = $store->bag->searcher(query => {name => "Patrick"});
    my $iterator = $store->bag->searcher(query => {name => "Patrick"}, fields => {_id => 0, name => 1});

    # Catmandu::Store::MongoDB supports CQL...
    my $hits = $store->bag->search(cql_query => 'name any "Patrick"');

=head1 DESCRIPTION

A Catmandu::Store::MongoDB is a Perl package that can store data into
L<MongoDB> databases. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called Catmandu::Bag-s.

=head1 METHODS

=head2 new(database_name => $name, %connection_opts)

=head2 new(database_name => $name , bags => { data => { cql_mapping => $cql_mapping } })

Create a new Catmandu::Store::MongoDB store with name $name. Optionally
provide connection parameters (see L<MongoDB::MongoClient> for possible
options).

The store supports CQL searches when a cql_mapping is provided. This hash
contains a translation of CQL fields into MongoDB searchable fields.

 # Example mapping
 $cql_mapping = {
     indexes => {
          title => {
            op => {
              'any'   => 1 ,
              'all'   => 1 ,
              '='     => 1 ,
              '<>'    => 1 ,
              'exact' => {field => [qw(mytitle.exact myalttitle.exact)]}
            } ,
            sort  => 1,
            field => 'mytitle',
            cb    => ['Biblio::Search', 'normalize_title']
          }
    }
 }

The CQL mapping above will support for the 'title' field the CQL operators:
 any, all, =, <> and exact.

The 'title' field will be mapped into the MongoDB field 'mytitle',
except for the 'exact' operator. In case of 'exact' both the
'mytitle.exact' and 'myalttitle.exact' fields will be searched.

The CQL mapping allows for sorting on the 'title' field. If, for instance, we
would like to use a special MongoDB field for sorting we could have written
"sort => { field => 'mytitle.sort' }".

The CQL has an optional callback field 'cb' which contains a reference to subroutines
to rewrite or augment the search query. In this case, in the Biblio::Search package
contains a normalize_title subroutine which returns a string or an ARRAY of string
with augmented title(s). E.g.

    package Biblio::Search;

    sub normalize_title {
       my ($self,$title) = @_;
       # delete all bad characters
       my $new_title =~ s{[^A-Z0-9]+}{}g;
       $new_title;
    }

    1;

=head2 bag($name)

Create or retieve a bag with name $name. Returns a L<Catmandu::Bag>.

=head2 client

Return the L<MongoDB::MongoClient> instance.

=head2 database

Return a L<MongoDB::Database> instance.

=head2 drop

Delete the store and all it's bags.

=head2 transaction(\&sub)

Execute C<$sub> within a transaction. See L<Catmandu::Transactional>.

Note that only MongoDB databases with feature compatibility >= 4.0 and in a
replica set have support for transactions.  See
L<https://docs.mongodb.com/manual/reference/command/setFeatureCompatibilityVersion/#view-fcv>
and
L<https://docs.mongodb.com/manual/tutorial/convert-standalone-to-replica-set/>
for more info.

=head1 Search

Search the database: see L<Catmandu::Searchable> and  L<Catmandu::CQLSearchable>. This module supports an additional search parameter:

    - fields => { <field> => <0|1> } : limit fields to return from a query (see L<MongoDB Tutorial|https://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>)

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::CQLSearchable>, L<Catmandu::Droppable>, L<Catmandu::Transactional>, L<MongoDB::MongoClient>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTORS

Johann Rolschewski, C<< <jorol at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
