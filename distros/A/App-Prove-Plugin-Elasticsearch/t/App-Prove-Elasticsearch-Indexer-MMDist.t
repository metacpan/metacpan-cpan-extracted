use strict;
use warnings;

use Test::More tests => 1;
use FindBin;

BEGIN: {
    $App::Prove::Elasticsearch::Indexer::MMDist::dfile = "$FindBin::Bin/data/Makefile.PL";
}

note $App::Prove::Elasticsearch::Indexer::MMDist::dfile;
note $App::Prove::Elasticsearch::Indexer::MMDist::index;
require App::Prove::Elasticsearch::Indexer::MMDist;
is($App::Prove::Elasticsearch::Indexer::MMDist::index,'App-Prove-Plugin-Elasticsearch',"DZIL module name found correctly");
