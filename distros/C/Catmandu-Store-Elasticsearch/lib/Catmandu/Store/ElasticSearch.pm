package Catmandu::Store::ElasticSearch;

use Catmandu::Sane;

our $VERSION = '1.0202';

use Search::Elasticsearch;
use Catmandu::Util qw(is_instance);
use Catmandu::Store::ElasticSearch::Bag;
use Moo;
use namespace::clean;

with 'Catmandu::Store';

has _es_args     => (is => 'rw', lazy => 1, default => sub {+{}});
has es           => (is => 'lazy');
has is_es_1_or_2 => (is => 'lazy', init_arg => undef);

sub BUILD {
    my ($self, $args) = @_;
    $self->_es_args($args);
}

sub _build_es {
    my ($self) = @_;
    Search::Elasticsearch->new($self->_es_args);
}

sub _build_is_es_1_or_2 {
    my ($self) = @_;
    is_instance($self->es, 'Search::Elasticsearch::Client::1_0::Direct')
        || is_instance($self->es,
        'Search::Elasticsearch::Client::2_0::Direct');
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::ElasticSearch - A searchable store backed by Elasticsearch

=head1 SYNOPSIS

    # From the command line

    # Import data into ElasticSearch
    $ catmandu import JSON to ElasticSearch --bag catmandu < data.json

    # Export data from ElasticSearch
    $ catmandu export ElasticSearch --bag catmandu to JSON > data.json

    # Export only one record
    $ catmandu export ElasticSearch --bag catmandu --id 1234

    # Export using an ElasticSearch query
    $ catmandu export ElasticSearch --bag catmandu --query "name:Recruitment OR name:college"

    # Export using a CQL query (needs a CQL mapping)
    $ catmandu export ElasticSearch --bag catmandu --cql-query "name any college"

    # You need to specify the client version if your Elasticsearch server version is
    # not the same as your default Search::Elasticsearch client version
    $ catmandu import JSON to ElasticSearch --bag catmandu --client '5_0::Direct' < data.json

    # From Perl

    use Catmandu;

    my $store = Catmandu->store('ElasticSearch');
    # options will be passed to the underlying Search::Elasticsearch client
    my $store = Catmandu->store('ElasticSearch', nodes => ['server.example.com:9200']);

    my $obj1 = $store->bag('catmandu')->add({ name => 'Patrick' });

    printf "obj1 stored as %s\n" , $obj1->{_id};

    # Force an id in the store
    my $obj2 = $store->bag('catmandu')->add({ _id => 'test123' , name => 'Nicolas' });

    # Commit all changes
    $store->bag('catmandu')->commit;

    $store->bag('catmandu')->delete('test123');

    $store->bag('catmandu')->delete_all;

    # All bags are iterators
    $store->bag->each(sub { ... });
    $store->bag->take(10)->each(sub { ... });

    # Query the store using a simple ElasticSearch query
    my $hits = $store->bag->search(query => '(content:this OR name:this) AND (content:that OR name:that)');

    # Native queries are also supported by providing a hash of terms
    # See the ElasticSearch manual for more examples
    my $hits = $store->bag->search(
        query => {
            # All name.exact fields that start with 'test'
            prefix => {
                'name.exact' => 'test'
            }
        } ,
        limit => 1000);

    # Catmandu::Store::ElasticSearch supports CQL...
    my $hits = $store->bag->search(cql_query => 'name any "Patrick"');

=head1 METHODS

=head2 new(%params)

=head2 new(%params, bags => { mybag => { index => 'myindex', mapping => \%map cql_mapping => \%map } })

Create a new Catmandu::Store::ElasticSearch store. ElasticSearch connection
parameters will be passed on to the underlying client.

Optionally provide for each bag a C<index> to indicate which index to use.
This defaults to the bag's name.

Optionally provide for each bag a C<type> to indicate the name of the mapping.
This defaults to the bag's name.

Optionally provide for each bag a C<mapping> which contains a ElasticSearch schema
for each field in the index (See below).

Optionally provide for each bag a C<cql_mapping> to map fields to CQL indexes.

Optionally provide for each bag an C<on_error> error handler (See below).

=head1 INHERITED METHODS

This Catmandu::Store implements:

=over 3

=item L<Catmandu::Store>

=back

Each Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=item L<Catmandu::Droppable>

=item L<Catmandu::Searchable>

=item L<Catmandu::CQLSearchable>

=back

=head1 INDEX MAPPING

The mapping contains a Elasticsearch schema mappings for each
bag defined in the index. E.g.

    {
        properties => {
            title => {
                type => 'text'
            }
        }
    }

See L<https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html>
for more information on mappings.

These mappings can be passed inside a Perl program, or be written into a
Catmandu 'catmandu.yml' configuration file. E.g.

   # catmandu.yml
   store:
       search:
          package: ElasticSearch
          options:
            bags:
              mybag:
                mapping:
                  properties:
                    title:
                      type: text

Via the command line these configuration parameters can be read in by using the
name of the store, C<search> in this case:

   $ catmandu import JSON to search --bag mybag < data.json
   $ catmandu export search --bag mybag to JSON > data.json

=head1 CQL MAPPING

Catmandu::Store::ElasticSearch supports CQL searches when a cql_mapping is provided
for each bag. This hash contains a translation of CQL fields into Elasticsearch
searchable fields.

 # Example mapping
  {
    indexes => {
      title => {
        op => {
          'any'   => 1 ,
          'all'   => 1 ,
          '='     => 1 ,
          '<>'    => 1 ,
          'exact' => {field => [qw(mytitle.exact myalttitle.exact)]}
        } ,
        field => 'mytitle',
        sort  => 1,
        cb    => ['Biblio::Search', 'normalize_title']
      }
    }
 }

The CQL mapping above will support for the 'title' field the CQL operators:
any, all, =, <> and exact.

The 'title' field will be mapping into the Elasticsearch field 'mytitle', except
for the 'exact' operator. In case of 'exact' we will search both the
'mytitle.exact' and 'myalttitle.exact' fields.

The CQL mapping allows for sorting on the 'title' field. If, for instance, we
would like to use a special ElasticSearch field for sorting we could
have written "sort => { field => 'mytitle.sort' }".

The callback field C<cb> contains a reference to subroutines to rewrite or
augment a search query. In this case, the Biblio::Search package contains a
normalize_title subroutine which returns a string or an ARRAY of strings
with augmented title(s). E.g.

    package Biblio::Search;

    sub normalize_title {
       my ($self,$title) = @_;
       my $new_title =~ s{[^A-Z0-9]+}{}g;
       $new_title;
    }

    1;

Also this configuration can be added to a catmandu.yml configuration file like:

    # catmandu.yml
    store:
        search:
           package: ElasticSearch
           options:
             client: 6_0::Direct
             bags:
               book:
                 mapping:
                   properties:
                     title:
                       type: text
                 cql_mapping:
                   indexes:
                       title:
                           op:
                               'any': true
                               'all': true
                               '=':   true
                               '<>':  true
                               'exact':
                                   field: [ 'mytitle.exact' , 'myalttitle.exact' ]
                           field: mytitle
                           sort: true
                           cb: [ 'Biblio::Search' , 'normalize_title' ]

Via the command line these configuration parameters can be read in by using the
name of the store, C<search> in this case:

   $ catmandu export search --bag book -q 'title any blablabla' to JSON > data.json

=head1 COMPATIBILITY

The appropriate client should be installed:

    # Elasticsearch 6.x
    cpanm Search::Elasticsearch::Client::6_0::Direct
    # Elasticsearch 1.x
    cpanm Search::Elasticsearch::Client::1_0::Direct

And specified in the options:

    Catmandu::Store::ElasticSearch->new(client => '1_0::Direct')

If you want to use the C<delete_by_query> method with Elasticsearch 2.0 you
have to L<install the delete by query plugin|https://www.elastic.co/guide/en/elasticsearch/plugins/current/plugins-delete-by-query.html>.

=head1 ERROR HANDLING

Error handling can be activated by specifying an error handling callback for index when creating
a store. E.g. to create an error handler for the bag 'data' index use:

    my $error_handler = sub {
        my ($action, $response, $i) = @_;
        do_something_with_error($response);
    };

    my $store = Catmandu::Store::ElasticSearch->new(
        bags => { data => { on_error => $error_handler } }
    });

Instead of a callback, the following shortcuts are also accepted for on_error:

log: log the response

throw: throw the response as an error

ignore: do nothing

    my $store = Catmandu::Store::ElasticSearch->new(
        bags => { data => { on_error => 'log' } }
    });

=head1 UPGRADING FROM A PRE 1.0 VERSION

Versions of this store < 1.0 used Elasticsearch types to map bags to a single
index. Support for multiple types in one index has since been removed from
Elasticsearch and since 1.0 each bag is mapped to an index.

You need to export you data before upgrading, update the configuration and then
import you data again.

=head1 SEE ALSO

L<Catmandu::Store>

=head1 AUTHOR

=over 4

=item Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=back

=head1 CONTRIBUTORS

=over 4

=item Dave Sherohman, C<< dave.sherohman at ub.lu.se >>

=item Robin Sheat, C<< robin at kallisti.net.nz >>

=item Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
