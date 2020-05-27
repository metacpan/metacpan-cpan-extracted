use Data::AnyXfer::Test::Kit;

use lib 't/lib';

use Employee::Search;
use Employee::IndexInfo;

use Data::AnyXfer::Elastic                   ();
use Data::AnyXfer::Elastic::Import::DataFile ();
use Data::AnyXfer::Elastic::Importer         ();
use Data::AnyXfer::Elastic::Logger           ();

################################################################################

# THE FOLLOWING WILL BE REPLACED WITH IMPORTER


my $index_info = Employee::IndexInfo->new;
my $datafile   = Data::AnyXfer::Elastic::Import::DataFile->new(
    index_info => $index_info,    #
);


# populate datafile
for ( Employee::IndexInfo->sample_documents ) {
    $datafile->add_document($_);
}


# synchronise data
$datafile->write;


# delete any existing indices for alias (within mangled namespace)
my $indices = $index_info->get_indices;
my $alias = eval { $indices->get_alias( name => $datafile->alias ) };

if ($alias) {
    my @indices = keys %{$alias};
    $indices->delete( index => $_ ) for @indices;
}


# import the documents
my $importer
    = Data::AnyXfer::Elastic::Importer->new( logger =>
        Data::AnyXfer::Elastic::Logger->new( file => 0, screen => 0 )
    );
$importer->deploy(
    datafile => $datafile,
    clients  => [ $indices->elasticsearch ]
);


sleep(2);    # allow elasticsearch to catch up

################################################################################

my $searcher = Employee::Search->new;

is_deeply $searcher->_es_simple_search(
    body => {    #
        query => {    #
            term => {    #
                last_name => { value => 'foobar' }
            }
        }
    }
    ),
    [],
    'WHERE first_name=`foobar`';

is_deeply                #
    $searcher->_es_simple_search(
    body => {
        query => {       #
            term => {    #
                first_name => { value => 'Jessica' },    #
            }
        },
        size => 1,
    }
    ),
    [
    {   email      => 'jedwards3@taobao.com',
        first_name => 'Jessica',
        id         => 4,
        last_name  => "Edwards"
    }
    ],                                                   #
    'WHERE first_name=`jessica`';                        #

is_deeply                                                #
    $searcher->_es_simple_search(
    body => {
        query => {
            range => {
                id => {
                    from => 1,
                    to   => 2
                }
            }
        },

        # this is required because we are testing the document order
        sort => [ { first_name => { order => 'asc' } } ]
    }
    ),
    [
    {   id         => 2,
        first_name => "Randy",
        last_name  => "Cunningham",
        email      => 'rcunningham1@tripod.com'
    },
    {   id         => 1,
        first_name => "Wayne",
        last_name  => "Duncan",
        email      => 'wduncan0@berkeley.edu'
    },
    ],
    'WHERE id => 1 AND id <= 2';


done_testing;
