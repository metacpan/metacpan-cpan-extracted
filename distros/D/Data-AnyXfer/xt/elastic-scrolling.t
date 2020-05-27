use Data::AnyXfer::Test::Kit;

use lib 't/lib';

use Data::AnyXfer::Elastic                   ();
use Data::AnyXfer::Elastic::IndexInfo        ();
use Data::AnyXfer::Elastic::Import::DataFile ();
use Data::AnyXfer::Elastic::Test::Import     ();

# create the IndexInfo (with name mangling)

my $index_info = Data::AnyXfer::Elastic::IndexInfo->new(
    alias => 'scroll_search',
    silo  => 'public_data',
    type  => 'scroll_test',
);

my $datafile = Data::AnyXfer::Elastic::Import::DataFile->new(
    index_info => $index_info, );

# insert 10 documents

for ( 1 .. 10 ) {
    $datafile->add_document( { count => $_ } );
}
$datafile->write;

Data::AnyXfer::Elastic::Test::Import->import_test_data(
    datafile => $datafile );


# create a new search object

my $search_meta = Moo::Meta::Class->create_anon_class(
    roles   => ['Data::AnyXfer::Elastic::Role::Project'],
    methods => {
        index_info => sub {$index_info}
    },
);
my $search = $search_meta->new_object;

# check that searches work

my $scroll_helper = $search->_es_simple_search(
    body        => { query => { range => { count => { lte => 5, }, }, } },
    scroll_size => 10,
);

$scroll_helper->refill_buffer;
is $scroll_helper->buffer_size, 5, 'search matched results';

# search with scrolling (5 at a time)

$scroll_helper = $search->_es_simple_search(
    body        => { query => { match_all => {}, }, },
    scroll_size => 5,
);


# loop through and count each document

my $count = 0;
while ( my $result = $scroll_helper->next ) {

    if ( $count == 0 ) {
        ok exists $result->{count}, 'check documents were extracted';
    }

    ok $result, "found result - " . ++$count;
}

# check number of documents returned

is $count, 10, 'scrolled through all relults';

# check fetching buffer

$scroll_helper = $search->_es_simple_search(
    body        => { query => { match_all => {}, }, },
    scroll_size => 10,
);

$scroll_helper->refill_buffer;

my @results = $scroll_helper->drain_buffer;

is @results, 10, 'buffer filled';

$scroll_helper->refill_buffer;

ok !$scroll_helper->buffer_size, 'no more results in buffer';



done_testing;

