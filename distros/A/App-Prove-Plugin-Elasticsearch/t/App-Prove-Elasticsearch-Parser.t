use strict;
use warnings;

use Test::More tests => 15;
use Test::Fatal;
use Test::Deep;
use Capture::Tiny qw{capture_merged};

use FindBin;
use App::Prove::Elasticsearch::Parser;

{
    is(exception { App::Prove::Elasticsearch::Parser::_require_indexer('App::Prove::Elasticsearch::Indexer') }, undef, "Can require indexer OK");
}

{
    no warnings qw{redefine once};
    local *App::Prove::Elasticsearch::Indexer::index_results                 = sub { };
    local *App::Prove::Elasticsearch::Blamer::Default::get_responsible_party = sub { return 'billy' };
    local *App::Prove::Elasticsearch::Versioner::Default::get_version        = sub { return '666' };
    local *App::Prove::Elasticsearch::Versioner::Default::get_file_version   = sub { return '666' };
    local *App::Prove::Elasticsearch::Platformer::Default::get_platforms     = sub { return ['zippyOS'] };
    local *App::Prove::Elasticsearch::Utils::require_versioner               = sub { return 'App::Prove::Elasticsearch::Versioner::Default'  };
    local *App::Prove::Elasticsearch::Utils::require_platformer              = sub { return 'App::Prove::Elasticsearch::Platformer::Default' };
    local *App::Prove::Elasticsearch::Utils::require_blamer                  = sub { return 'App::Prove::Elasticsearch::Blamer::Default'     };
    local *App::Prove::Elasticsearch::Parser::_require_indexer               = sub {};
    use warnings;

    my $opts = { 'server.host'       => 'zippy.test',
                 'server.port'       => 666,
                 'client.indexer'    => 'App::Prove::Elasticsearch::Indexer',
                 'client.blamer'     => 'Default',
                 'client.platformer' => 'Default',
                 'client.versioner'  => 'Default',
                 'ignore_exit'       => undef,
                 'merge'             => 1,
                 'source'            => "$FindBin::Bin/data/pass.test",
                 'spool'             => undef,
                 'switches'          => [],
    };

    my $p;
    is(exception { $p = App::Prove::Elasticsearch::Parser->new( $opts ) }, undef, "make_parser executes all the way through");
    SKIP: {
        skip("Couldn't build parser",9) unless $p;
        is(exception {$p->run()}, undef, "Running parser works");
        is($p->{upload}->{version},'666',"Version correctly recognized");
        is($p->{upload}->{executor},'billy',"Executor correctly recognized");
        is($p->{upload}->{path},"$FindBin::Bin/data","Path correctly recognized");
        is($p->{upload}->{name},"pass.test","Test name correctly recognized");
        cmp_bag($p->{upload}->{platform},['zippyOS'],"Platform(s) correctly recognized");
        #status, steps, body
        like($p->{upload}->{body},qr/yay/i,"Full test output captured");
        is(scalar(@{$p->{upload}->{steps}}),1,"Test steps captured");
        is($p->{upload}->{status},'OK',"Test status captured");
    }

    #Verify status overrides
    $opts->{source} = "$FindBin::Bin/data/discard.test";
    is(exception { $p = App::Prove::Elasticsearch::Parser->new( $opts ) }, undef, "make_parser executes all the way through");
    SKIP: {
        skip("Couldn't build parser",3) unless $p;
        is(exception {$p->run()}, undef, "Running parser works");
        is($p->{global_status},'DISCARD',"Global status override correctly acquired");
        is($p->{upload},undef,"Made no attempt to upload when status DISCARD was indicated");
    }
}
