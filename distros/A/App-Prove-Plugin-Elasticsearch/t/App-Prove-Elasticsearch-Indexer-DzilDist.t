use strict;
use warnings;

use Test::More tests => 1;
use FindBin;

BEGIN: {
    $App::Prove::Elasticsearch::Indexer::DzilDist::dfile = "$FindBin::Bin/data/discard.test";
}

note $App::Prove::Elasticsearch::Indexer::DzilDist::dfile;
note $App::Prove::Elasticsearch::Indexer::DzilDist::index;
require App::Prove::Elasticsearch::Indexer::DzilDist;
is($App::Prove::Elasticsearch::Indexer::DzilDist::index,'SomeDist',"DZIL module name found correctly");
