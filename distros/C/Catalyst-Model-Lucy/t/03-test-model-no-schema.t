use Test::More tests => 7;
use FindBin;
use lib 't/lib';

_build_index();

use_ok('TestAppNoSchema');
my $subject = TestAppNoSchema->model('Lucy');
$subject->indexer->add_doc({title=>'foo', desc=>'bar'});
$subject->indexer->commit;

isa_ok $subject->index_searcher, "Lucy::Search::IndexSearcher", "We have a Lucy Searcher Obj";
like $subject->index_path, qr#t/test_index#, "Correct index path";
is $subject->num_wanted, 20, "Page size is 20";

my $hits = $subject->hits( query=>'foo' );
is $hits->total_hits, 2, "Should only be 2 hits";

while ( my $hit = $hits->next ) {
    is $hit->{desc}, "bar", "Instance of bar found";
}


sub _build_index {
    require Catalyst::Model::Lucy; 
    my $i = Catalyst::Model::Lucy->new(
         index_path     => File::Spec->catfile($FindBin::Bin,'test_index'),
         num_wanted     => 20,
         language       => 'en',
         create_index   => 1,   # We create it from nothing
         truncate_index => 1,   # If exists we truncate
         schema_params  => [
                               { name => 'title' },
                               { name => 'desc' }
                           ]
    );

    $i->indexer->add_doc({title=>'foo', desc=>'bar'});
    $i->indexer->commit;
    undef $i;
}
