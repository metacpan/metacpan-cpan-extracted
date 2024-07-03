use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
  Catmandu::Store::OpenSearch
  Catmandu::Store::OpenSearch::Bag
  Catmandu::Store::OpenSearch::Searcher
  Catmandu::Store::OpenSearch::CQL
);

done_testing;