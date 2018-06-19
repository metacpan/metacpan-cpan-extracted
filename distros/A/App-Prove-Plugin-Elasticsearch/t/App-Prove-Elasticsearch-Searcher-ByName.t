use strict;
use warnings;

use Test::More tests => 9;
use Test::Fatal;
use Test::Deep;

use App::Prove::Elasticsearch::Indexer;
use App::Prove::Elasticsearch::Searcher::ByName;

{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::new = sub { return 1 };
    local *App::Prove::Elasticsearch::Utils::require_versioner = sub {};
    local *App::Prove::Elasticsearch::Utils::require_platformer = sub {};
    use warnings;

    my $indexer = bless({},'App::Prove::Elasticsearch::Indexer');
    my $input = {
        'server.host' => 'whee.test',
        'server.port' => '666',
    };
    is( exception { App::Prove::Elasticsearch::Searcher::ByName->new( $input, $indexer) }, undef, "Constructor works");
}

{

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub {
        my ($self,%q) = @_;
        return { hits => { hits => [ { _source => { name => 'zippy.test', version => '666.420', platform => 'a' } } ] } };
    };
    local *Cwd::abs_path = sub { return shift };
    local *File::Basename::basename = sub { return (split(/\//,shift))[-1] };
    local *File::Basename::dirname  = sub { return shift };
    local *main::get_version = sub {
        return '666.420';
    };
    local *main::get_platforms = sub {
        return ['a'];
    };
    local *App::Prove::Elasticsearch::Searcher::ByName::_has_results = sub { return 1 };
    use warnings;

    my $s = bless({'platformer' => 'main', 'versioner' => 'main', 'handle' => bless({ },'Search::Elasticsearch') },'App::Prove::Elasticsearch::Searcher::ByName');
    my @res = $s->filter('/path/to/zippy.test');
    cmp_bag(\@res,[],"bad tests get filtered out");

    @res = $s->filter('t/data/pass.test');
    cmp_bag(\@res,['t/data/pass.test'],"good tests *dont* get filtered out");

    no warnings qw{redefine once};
    local *main::get_platforms = sub { return [] };
    use warnings;

    @res = $s->filter('/path/to/zippy.test');
    cmp_bag(\@res,['/path/to/zippy.test'],"No platforms correctly recognized as being wrong");

    no warnings qw{redefine once};
    local *main::get_version = sub { return '666.421' };
    use warnings;

    @res = $s->filter('/path/to/zippy.test');
    cmp_bag(\@res,['/path/to/zippy.test'],"Wrong version correctly recognized as being wrong");

}

{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [] } } };
    use warnings;

    my $e = bless({},'Search::Elasticsearch');
    my $obj = { handle => $e, index => 'zippy' };
    is(App::Prove::Elasticsearch::Searcher::ByName::_has_results($obj), 0, "No hits returns false.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [1], total => 3 } } };
    use warnings;

    is(App::Prove::Elasticsearch::Searcher::ByName::_has_results($obj), 3, "Get a true value when there are 3 hits.");

}

{
    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [] } } };
    local *App::Prove::Elasticsearch::Searcher::ByName::_has_results = sub { return 1 };
    use warnings;

    my $e = bless({},'Search::Elasticsearch');
    my $obj = bless({ handle => $e, index => 'zippy' },"App::Prove::Elasticsearch::Searcher::ByName");
    my $expected = [{ name => 'zippy.t', status => 'UNTESTED', body => ''},{ name => 'tickle.t', status => 'UNTESTED', body => ''}];
    my @got = $obj->get_test_replay(666,['moo'],'zippy.t','tickle.t');
    cmp_bag(\@got, $expected, "No hits returns tests as UNTESTED.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [{ _source => 'whee' }] } } };
    use warnings;
    $expected = ['whee', 'whee'];
    @got = $obj->get_test_replay(666,[],'zippy.t','tickle.t');
    cmp_bag(\@got, $expected, "Raw result returned when hits are recieved");

}


