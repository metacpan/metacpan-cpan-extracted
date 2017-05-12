use Test::More;

use lib 't/lib';

use Dancer::Test apps => [ 't::lib::TestApp' ];
use Dancer::Plugin::DBIC qw(rset schema);
use Dancer qw(:syntax :tests);
use t::lib::TestApp;

eval { require DBD::SQLite };
plan skip_all => 'DBD::SQLite required to run these tests' if $@;

set plugins => {
    DBIC => {
        foo => {
            schema_class => 'Foo',
            dsn          =>  'dbi:SQLite:dbname=:memory:',
        },
    }
};

schema->deploy;
ok rset('User')->create({ name => 'sukria' });
ok rset('User')->create({ name => 'bigpresh' });

response_status_is    [ GET => '/' ], 200,   "GET / is found";
response_content_like [ GET => '/' ], qr/2/, "content looks good for /";

response_status_is [ GET => '/user/sukria' ], 200, 'GET /user/sukria is found';

response_content_like [ GET => '/user/sukria' ], qr/sukria/,
  'content looks good for /user/sukria';
response_content_like [ GET => '/user/bigpresh' ], qr/bigpresh/,
  "content looks good for /user/bigpresh";

response_status_is [ DELETE => '/user/bigpresh' ], 200,
    'DELETE /user/bigpresh is ok';
response_content_like [ GET => '/' ], qr/1/, 'content looks good for /';

done_testing;
