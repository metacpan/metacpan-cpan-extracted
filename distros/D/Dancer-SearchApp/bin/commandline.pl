#!perl -w
use strict;
#use Search::Elasticsearch::Async;
#use Promises backend => ['AnyEvent'];
use Search::Elasticsearch;
use Getopt::Long;

GetOptions(
    'force|f' => \my $force_rebuild,
    'config-file|c' => \my $config_file,
);

# Connect to localhost:9200:

#my $e = Search::Elasticsearch::Async->new();

# Round-robin between two nodes:

my $index_name = 'dancer-searchapp';

my $e = Search::Elasticsearch->new(
    nodes => [
        'localhost:9200',
        #'search2:9200'
    ]
);

if( $force_rebuild ) {
    $e->indices->delete( index => $index_name );
};

if( ! $e->indices->exists( index => $index_name )) {
    $e->indices->create(index=>$index_name);
    $e->indices->put_settings( index => $index_name,
        body => {
        "index" => {
            "number_of_replicas" => 0
        }
    });
};

# Connect to cluster at search1:9200, sniff all nodes and round-robin between them:

#my $e = Search::Elasticsearch::Async->new(
#    nodes    => 'search1:9300',
#    cxn_pool => 'Async::Sniff'
#);

my $add_item;
if( $add_item ) {
    $e->index(
            index   => $index_name,
            type    => 'blog_post',
            id      => 1,
            body    => {
                title   => 'Elasticsearch clients',
                content => 'Interesting content...',
                date    => '2013-09-24'
            }
        );
};

# Search:
use Data::Dumper;

    my $results = $e->search(
        index => $index_name,
        body  => {
            query => {
                match => { title => 'elasticsearch' }
            }
        }
    );
warn Dumper $results;

    $results = $e->cluster->health(
        index => $index_name,
    );
warn Dumper $results;