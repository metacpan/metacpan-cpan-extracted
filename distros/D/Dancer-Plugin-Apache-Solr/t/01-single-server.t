use strict;
use warnings;
use Test::More;
use Dancer qw(:syntax :tests);
use Dancer::Plugin::Apache::Solr;

set plugins => {
  'Apache::Solr' => {
    foo => {
      server => 'https://example.com/search',
    },
  }
};

subtest 'solr' => sub {
  my $solr = solr;
  isa_ok($solr, 'Apache::Solr');
  is( $solr->server , 'https://example.com/search', 'pointing to correct server');
};

done_testing;