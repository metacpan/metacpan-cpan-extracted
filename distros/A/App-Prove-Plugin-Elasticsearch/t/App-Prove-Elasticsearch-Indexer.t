use strict;
use warnings;

use Test::More tests => 17;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use App::Prove::Elasticsearch::Indexer;

#check_index
{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return bless({},'Search::Elasticsearch') };
    local *Search::Elasticsearch::indices = sub { return bless({},'Search::Elasticsearch::Indices') };
    local *Search::Elasticsearch::Indices::exists = sub { return 1};
    use warnings;

    like(exception { App::Prove::Elasticsearch::Indexer::check_index() }, qr/server must be specified/i,"Indexer dies in the event server & port  is not specified");
    like(exception { App::Prove::Elasticsearch::Indexer::check_index({ 'server.port' => 666 }) }, qr/server must be specified/i,"Indexer dies in the event server are not specified");
    like(exception { App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' =>'zippy.test' }) }, qr/port must be specified/i,"Indexer dies in the event port is not specified");

    is(App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' => 'zippy.test', 'server.port' => 666}),0,"Indexer skips indexing in the event index already exists.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::Indices::exists = sub { return 0 };
    local *Search::Elasticsearch::Indices::create = sub { };
    use warnings;

    is(App::Prove::Elasticsearch::Indexer::check_index({ 'server.host' => 'zippy.test', 'server.port' => 666 }),1,"Indexer runs in the event index nonexistant.");
}

#index_results
{
    $App::Prove::Elasticsearch::Indexer::e = undef;
    like( exception { App::Prove::Elasticsearch::Indexer::index_results({ name => 'zippy.test' }) }, qr/check_index must be run/, "index_results fails if check_index not run first");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return bless({},'Search::Elasticsearch') };
    local *Search::Elasticsearch::index = sub { };
    local *Search::Elasticsearch::exists = sub { return 1};
    local *App::Prove::Elasticsearch::Utils::get_last_index = sub { return 0 };
    use warnings;

    $App::Prove::Elasticsearch::Indexer::e = bless({},'Search::Elasticsearch');
    is(App::Prove::Elasticsearch::Indexer::index_results({ name => 'zippy.test' }), 1, "index_result returns 1 in the event indexing succeeds.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::exists = sub { return 0 };
    use warnings;

    like( exception { App::Prove::Elasticsearch::Indexer::index_results({ name => 'zippy.test' }) }, qr/failed to index/i, "check_index dies in event of failure.");

}

# associate_case_with_result
{
    $App::Prove::Elasticsearch::Indexer::e = undef;
    like( exception { App::Prove::Elasticsearch::Indexer::associate_case_with_result() }, qr/check_index must be run/, "associate_case_with_result fails if check_index not run first");

    my %args = (
        platforms => ['clownOS', 'clownBrowser'],
        versions  => ['666.666'],
        defects   => ['YOLO-666'],
        case      => 'zippy.test',
        status    => 'TEST BAD',
    );

    local $ENV{SERVER_HOST} = 'zippy.doodah';
    local $ENV{SERVER_PORT} = '666';

    my %searchargs;
    my %arg2check;
    my $searchreturn = {
        hits => {
            hits => [
                {
                    _id => 666,
                    _source => {
                        name     => 'zippy.test',
                        version  => '666.666',
                        platform => ['clownOS','clownBrowser'],
                    }
                }
            ]
        }
    };

    $App::Prove::Elasticsearch::Indexer::e = bless({},'BogusSearch');
    no warnings qw{redefine once};
    local *BogusSearch::search = sub { shift; %searchargs = @_; return $searchreturn };
    local *BogusSearch::update = sub { shift; %arg2check = @_; return { result => 'updated' } };
    use warnings;

    my $expected_search = {
        index => 'testsuite',
        from  => 0,
        size  => $App::Prove::Elasticsearch::Indexer::max_query_size,
        body  => {
            query => {
                bool => {
                    must => [
                        {match => {
                            name => 'zippy.test',
                        }},
                        {match => {
                            platform => 'clownOS',
                        }},
                        {match => {
                            platform => 'clownBrowser',
                        }},
                    ],
                    should => [
                        {match => {
                            version => '666.666',
                        }},
                    ],
                },
            },
        },
    };
    my $expected_update = {
        index => 'testsuite',
        id    => 666,
        type  => 'result',
        body  => {
            doc => {
                defect => ['YOLO-666'],
                status => 'TEST BAD',
            },
        }
    };

    like(capture_merged { App::Prove::Elasticsearch::Indexer::associate_case_with_result(%args) },qr/document 666/i,"can associate case with result if everything works");
    is_deeply(\%searchargs,$expected_search,"arguments passed to search appear correct") or diag explain \%searchargs;
    is_deeply(\%arg2check,$expected_update,"arguments passed to update appear correct") or diag explain \%arg2check;

    #Check the case where we get a failure
    no warnings qw{redefine once};
    local *BogusSearch::update = sub { shift; %arg2check = @_; return { result => 'noop' } };
    use warnings;
    is(capture_merged { App::Prove::Elasticsearch::Indexer::associate_case_with_result(%args) },'',"No output when case already associated");

    #Check the case where we get a failure
    no warnings qw{redefine once};
    local *BogusSearch::update = sub { shift; %arg2check = @_; return { result => 'error' } };
    use warnings;
    is(App::Prove::Elasticsearch::Indexer::associate_case_with_result(%args),1,"Number of errors encountered reported");


    #Check the case where we have bad version/platform/name returned
    {
        local $args{platforms} = ['zipadoodah'];
        like(capture_merged {App::Prove::Elasticsearch::Indexer::associate_case_with_result(%args)},qr/No cases matching your query/i,"No cases updated if we don't find correct platform");
    }
    {
        local $args{versions} = ['zipadoodah'];
        like(capture_merged {App::Prove::Elasticsearch::Indexer::associate_case_with_result(%args)},qr/No cases matching your query/i,"No cases updated if we don't find correct versions");
    }
    {
        local $args{case} = 'zipadoodah';
        like(capture_merged {App::Prove::Elasticsearch::Indexer::associate_case_with_result(%args)},qr/No cases matching your query/i,"No cases updated if we don't find correct case");
    }
}
