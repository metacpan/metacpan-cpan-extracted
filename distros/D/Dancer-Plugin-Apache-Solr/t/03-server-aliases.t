use strict;
use warnings;
use Test::More;
use Dancer qw(:syntax :tests);
use Dancer::Plugin::Apache::Solr;
use Test::Exception;

set plugins => {
  'Apache::Solr' => {
    default => {
      server => 'https://example.com/foo',
    },
    foo => {
      alias => 'default',
    },
    badalias => {
      alias => 'zzz',
    },
  }
};

subtest 'default schema' => sub {
  isa_ok(solr, 'Apache::Solr');
  is( solr->server , 'https://example.com/foo', 'pointing to correct server');
};

subtest 'schema alias' => sub {
  isa_ok(solr('foo'), 'Apache::Solr');
  is( solr('foo')->server , 'https://example.com/foo', 'pointing to correct server');
};

subtest 'bad alias' => sub {
  throws_ok { solr('badalias') }
    qr/server alias zzz does not exist in the config/,
    'got bad alias error';
};

done_testing();