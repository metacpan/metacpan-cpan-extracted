use strict;
use warnings;
use Test::More;
use Dancer qw(:syntax :tests);
use Dancer::Plugin::Apache::Solr;
use Test::Exception;

subtest 'two servers' => sub {
  set plugins => {
    'Apache::Solr' => {
      foo => {
        server => 'https://example.com/foo',
      },
      bar => {
        server => 'https://example.com/bar',
      },
    }
  };

  throws_ok { solr('f') }
    qr/server f is not configured/,
    'Missing server error thrown';

  throws_ok { solr }
    qr/The server default is not configured/,
    'Missing default server error thrown';
};

subtest 'two servers with a default server' => sub {
  set plugins => {
    'Apache::Solr' => {
      default => {
        server => 'https://example.com/foo',
      },
      bar => {
        server => 'https://example.com/bar',
      },
    }
  };

  my $solr = solr;
  isa_ok($solr, 'Apache::Solr');
  is( $solr->server , 'https://example.com/foo', 'pointing to correct server');
};

done_testing;