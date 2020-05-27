package Data::AnyXfer::Elastic::Readme;

use strict;
use warnings;

1;

=head1 Setting up a Elasticsearch Project

=head2 Introduction

Our Elasticsearch search setup is specifically tailored for use with our projects 
and environment. It shouldn't be complicated to use and will fit right in! This 
document aims to give a brief overview of how to use Elasticsearch in your project; 
from indexing documents, making the index live and finally searching your index. 
We will run through a basic project to demonstrate how Elasticsearch is incorporated 
into the project.



=head2 Configure your Index (MyProject::IndexInfo)

The crucial part of your project should be the IndexInfo module. It defines:

 - How the index is mapped.
 - What it's called.
 - How to search it.
 - Where does the data live.

Here's the basic structure of an index info module:

    package MyProject::IndexInfo;

    extends 'Data::AnyXfer::Elastic::IndexInfo';
    with 'Data::AnyXfer::Elastic::Role::IndexInfo';

    sub define_index_info {
        return (
            alias    => 'interiors',
            silo     => 'public_data',
            type     => 'tagged_photograph',
            mappings => { ... },
            settings => { ... },
        );
    }

    1;

=head3 Alias

The alias defined in your index info class will automatically be applied to any indexes created 
using it. This alias will then be used during read operations, and in turn any code using the 
L<Data::AnyXfer::Elastic::Role::IndexInfo/get_index|get_index> method will automatically 
receive a L<Data::AnyXfer::Elastic::Index> instance configured to point at it.

=head3 Silo

The silo defined in your index info class will be used to find the correct elasticsearch cluster 
which is configured and allowed to store the data for your index. Currently the environment is 
split into two silos.

=over

=item public_data

This silo holds data which is allowed to be stored outside of the  network, to be made 
available to our web applications and hosting providers.

=item private_data

This silo holds data which is B<NOT> allowed to leave  internal networks. This data may 
be sensitive, of a financial nature, or subject to certain SOX/compliance-related restrictions.

=back

=head3 Mappings

In this example, C<mappings> should contain the mapping for your new type, ``tagged_photograph``.

A simple example would be:

    mappings => {
        tagged_photograph => {
            properties => {
                bedrooms => {
                    type  => "integer",
                    index => "not_analyzed"
                },
                exceptional => {
                    type  => "integer",
                    index => "not_analyzed"
                },
                location  => { type => "geo_point", },
                room_name => {
                    type  => "string",
                    index => "not_analyzed"
                },
                location_id => {
                    type  => "integer",
                    index => "not_analyzed"
                },
                photo_filename => {
                    type     => "string",
                    analyzer => "string_lowercase"
                },
            }
        }
    }

See L<https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-object-type.html|mappings> for 
more info on elasticsearch mappings.


=head2 Using your new Index (MyProject::Role::Elasticsearch)

The next stage is to consume the C<Data::AnyXfer::Elastic::Role::Project>
role. The project role requires that we provide our IndexInfo object using an
C<index_info> attribute. All Elasticsearch helper methods will then use this
information to make the right connections and operate on your data.

    package MyProject::Role::Elasticsearch;

    use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
    use MyProject::IndexInfo;

    has index_info => (
        is       => 'ro',
        isa      => MyProject::IndexInfo,
        default  => sub { return MyProject::IndexInfo->new; }
    );


    # important: this needs to be last!
    with 'Data::AnyXfer::Elastic::Role::Project';

    1;



=head2 Creating an Importer for your Index (MyProject::Import)

In order to store data in your index, you'll need to create an Import module for 
your project. This module will most likely use 
`Data::AnyXfer::To::Elasticsearch::DataFile` if your data is currently 
stored in the database, to create and play an elasticsearch datafile 
(L<Data::AnyXfer::Elastic::Import::DataFile>).

A datafile prepares and records data for bulk imports into Elasticsearch clusters. 
L<Data::AnyXfer::DbicToElasticsearch::DataFile> allows you to supply 
a L<DBIx::Class::ResultSet> instance as the datasource to create your index from.

If your data is not coming from a L<DBIx::Class::ResultSet>, you will in most cases 
subclass L<Data::AnyXfer::IteratorToElasticsearch::DataFile> directly, 
which allows a datasource implementing a standard perlish iterator iterface 
(any object with a ``next`` method, returning ``undef`` on exhaustion, 
or a ``CODE``ref doing the same).

Here is an example Import module:

    package MyProject::Import;

    use Moo;
use MooX::Types::MooseLike::Base qw(:all);


    use MyProject::IndexInfo;

    extends 'Data::AnyXfer::DbicToElasticsearch::DataFile';

    has '+index_info' => (
        default => sub {
            return MyProject::IndexInfo->new;
        }
    );

    around 'transform' => sub {

        my ( $self, $orig, @args ) = @_;
        my $data = $self->$orig(@args);

        # do data transformations ...

        return $data;
    };

    1;

If your transform method requires the full inflated dbic result instance, define an 
attribute override as C<fore_dbic_inflate>, and default it to true (C<1>).

B<I<This is strongly discouraged as it will significantly slow down data imports. 
Please parse your datetime columns etc. expliticly using L<DateTime::Format::MySQL> 
or related L<DateTime>::Format modules.>>



=head2 Publishing your Index (my_project_import_to_es)

Reads the datafile and streams data into Elasticsearch. On finalising the
index primary aliases are swapped making them live and old indices are unlinked
from the alias.

    use MyProject::Import ( );
    use Data::AnyXfer::Elastic::Importer ( );

    # create the datafile
    my $my_project = MyProject::Import->new;
    my $datafile = $my_project->export_datafile;

    my $es_importer = Data::AnyXfer::Elastic::Importer->new;

    # runs and finalises
    my $response = $es_importer->deploy(
        datafile         => $datafile,
        silo             => 'public_data',
    );

    exit(0);


If your Import class supllies full index information 
(as in L<./Configure your Index (MyProject::IndexInfo)> then you may want to simply
 use the ``autoplay_datafile`` attribute, available on all ``DataFile`` 
 targetted L<Data::AnyXfer> classes. 
 
 This should reduce the above script down to the following 2 simple lines: 

    use MyProject::Import ( );

    MyProject::Import->new( autoplay_datafile => 1 )->run;



=head2 Search your Index (MyProject::Houses)

This module gives an example of how to search your index. It is optional
and in reality any module in the namespace can use
C<MyProject::Role::Elasticsearch> to access the index.

    package MyProject::Houses;

    use Moo;
use MooX::Types::MooseLike::Base qw(:all);


    with 'MyProject::Role::Elasticsearch';

    # doing a simple search
    sub foo {
        return $_[0]->_es_simple_search(
            body => {
                query => {
                    term => { house => 'semi-detached' },
                }
            }
        );
    }

    1;

=cut

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

