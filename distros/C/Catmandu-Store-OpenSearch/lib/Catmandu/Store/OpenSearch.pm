package Catmandu::Store::OpenSearch;

our $VERSION = '0.01';

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Catmandu::Store::OpenSearch::Bag;
use Types::Standard qw(ArrayRef Str Bool);
use Types::Common::String qw(NonEmptyStr);
use Moo;
use OpenSearch;
use namespace::clean;

with 'Catmandu::Store';

has hosts => (
    is => 'lazy',
    isa => ArrayRef[NonEmptyStr],
    default => sub {["localhost:9200"]}
);

has user => (
    is => 'ro',
    isa => Str,
);

has pass => (
    is => 'ro',
    isa => Str,
);

has secure => (
    is  => 'lazy',
    isa => Bool,
);

has os => (is => 'lazy', init_arg => undef);

sub _build_secure {
    0;
}

sub _build_os {
    my $self = $_[0];
    OpenSearch->new(
        hosts => $self->hosts,
        user  => $self->user // "",
        pass  => $self->pass // "",
        secure=> $self->secure,
    );
}


1;


__END__

=pod

=head1 NAME

Catmandu::Store::OpenSearch - A searchable store backed by Opensearch

=head1 SYNOPSIS

    # From the command line

    # Import data into OpenSearch
    $ catmandu import JSON to OpenSearch --bag catmandu < data.json

    # Export data from OpenSearch
    $ catmandu export OpenSearch --bag catmandu to JSON > data.json

    # Export only one record
    $ catmandu export OpenSearch --bag catmandu --id 1234

    # Export using an OpenSearch query
    $ catmandu export OpenSearch --bag catmandu --query "name:Recruitment OR name:college"

    # Export using a CQL query (needs a CQL mapping)
    $ catmandu export OpenSearch --bag catmandu --cql-query "name any college"

    # From Perl

    use Catmandu;

    my $store = Catmandu->store('OpenSearch');

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

    # Query the store using a simple OpenSearch query
    my $hits = $store->bag->search(query => '(content:this OR name:this) AND (content:that OR name:that)');

    # Native queries are also supported by providing a hash of terms
    # See the OpenSearch manual for more examples
    my $hits = $store->bag->search(
        query => {
            # All name.exact fields that start with 'test'
            prefix => {
                'name.exact' => 'test'
            }
        } ,
        limit => 1000);

    # Catmandu::Store::OpenSearch supports CQL...
    my $hits = $store->bag->search(cql_query => 'name any "Patrick"');

=head1 CONSTRUCTOR ARGUMENTS

=over 3

=item hosts

Type: C<ArrayRef[Str]>

Description: List of opensearch hosts

Default: C<["localhost:9200"]>

Optional

=item user

Type: C<Str>

Description: username credential, when Basic Auth is needed

Optional

=item pass

Type: C<Str>

Description: password credential, when Basic Auth is needed

Optional

=item secure

Type: C<Bool> (C<0> or C<1>)

Description: access opensearch hosts over HTTPS

Default: C<0>

Optional

=item bags

Type: C<HashRef>

Typically looks like

    {
        "<bag>": {
            "index": "<opensearch-index-name>",
            "mapping": {
            
            },
            "cql_mapping": {
            
            }
        }
    }

Optionally provide for each bag a C<index> to indicate which index to use.
This defaults to the bag's name.

Optionally provide for each bag a C<mapping> which contains a OpenSearch schema
for each field in the index (See L</"INDEX MAPPING">).

Optionally provide for each bag a C<cql_mapping> to map fields to CQL indexes.
(See L</"CQL MAPPING">)

Optionally provide for each bag an C<on_error> error handler (See below).

=back

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

The mapping contains a OpenSearch schema mappings for each
bag defined in the index. E.g.

    {
        properties => {
            title => {
                type => 'text'
            }
        }
    }

See L<https://opensearch.org/docs/latest/field-types/>
for more information on mappings.

These mappings can be passed inside a Perl program, or be written into a
Catmandu 'catmandu.yml' configuration file. E.g.

   # catmandu.yml
   store:
       search:
          package: OpenSearch
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

Catmandu::Store::OpenSearch supports CQL searches when a cql_mapping is provided
for each bag. This hash contains a translation of CQL fields into OpenSearch
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

The 'title' field will be mapping into the OpenSearch field 'mytitle', except
for the 'exact' operator. In case of 'exact' we will search both the
'mytitle.exact' and 'myalttitle.exact' fields.

The CQL mapping allows for sorting on the 'title' field. If, for instance, we
would like to use a special OpenSearch field for sorting we could
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
           package: OpenSearch
           options:
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

This perl client works with the current Opensearch server 7.* at the moment of writing

=head1 ERROR HANDLING

Error handling can be activated by specifying an error handling callback for index when creating
a store. E.g. to create an error handler for the bag 'data' index use:

    my $error_handler = sub {
        my ($action, $response, $i) = @_;
        do_something_with_error($response);
    };

    my $store = Catmandu::Store::OpenSearch->new(
        bags => { data => { on_error => $error_handler } }
    });

Instead of a callback, the following shortcuts are also accepted for on_error:

log: log the response

throw: throw the response as an error

ignore: do nothing

    my $store = Catmandu::Store::OpenSearch->new(
        bags => { data => { on_error => 'log' } }
    });

=head1 SEE ALSO

L<Catmandu::Store>

=head1 AUTHOR

=over 4

=item Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=back

=head1 IMPORTANT

This module is still a work in progress, and needs further testing using it in a production system

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
