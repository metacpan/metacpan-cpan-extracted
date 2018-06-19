use strict;
use warnings;

use Test::More tests => 6;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use FindBin;
use App::Prove::Elasticsearch::Harness;
use App::Prove::Elasticsearch::Indexer;

{
    my $p = { verbosity => 1 };
    my $harness;
    is(exception { $harness = App::Prove::Elasticsearch::Harness->new($p) }, undef, "Happy path can execute all the way through");

    SKIP: {
        skip("Couldn't make harness",1) unless $harness;
        no warnings qw{redefine once};
        local *App::Prove::Elasticsearch::Parser::new = sub {};
        use warnings;

        my $scheduler = $harness->make_scheduler("$FindBin::Bin/data/pass.test");
        is(exception { $harness->make_parser($scheduler->get_job()) }, undef, "make_parser executes all the way through");
        #TODO check ENV is OK
    }
}

{

    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Harness::_require_deps = sub {};
    local *App::Prove::Elasticsearch::Harness::_filter_tests_with_results = sub { return @_ };
    local *TAP::Harness::runtests = sub { return 1 };
    use warnings;

    local $ENV{CLIENT_AUTODISCOVER} = 0;
    my $h = bless({},'App::Prove::Elasticsearch::Harness');
    is( $h->runtests( 'zippy.test' ), 1, "can runtests");

    local $ENV{CLIENT_AUTODISCOVER} = 1;
    is( $h->runtests( 'zippy.test' ), 1, "can runtests in autodiscover mode");
}

{
    my $obj = {
        'client.indexer' => 'main',
    };

    sub new {
        return bless({},'main');
    }
    sub filter {
        shift;
        return @_;
    }
    local $ENV{CLIENT_INDEXER} = 'App::Prove::Elasticsearch::Indexer';

    my ($t) = App::Prove::Elasticsearch::Harness::_filter_tests_with_results($obj,'main','zippy.test');
    is($t,'zippy.test',"_filter_tests_with_results returns results");
}

{
    local $ENV{CLIENT_INDEXER}      = 'App::Prove::Elasticsearch::Indexer';
    local $ENV{CLIENT_AUTODISCOVER} = 'ByName';
    is(exception { App::Prove::Elasticsearch::Harness::_require_deps() }, undef, "deps can be required");
}
