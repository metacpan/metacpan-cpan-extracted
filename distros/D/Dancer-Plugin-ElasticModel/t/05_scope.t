use Test::More import => ['!pass'];

use strict;
use warnings;
use lib 't/lib';
use Dancer ':syntax';
use Dancer::Test appdir => path( dirname($0), 'good', 'config.yml' );

BEGIN {
    use Search::Elasticsearch::Compat;
    unless (
        eval { Search::Elasticsearch::Compat->new->current_server_version } )
    {
        plan skip_all => 'No elasticsearch server available';
        exit;
    }
    plan tests => 10;
    config->{plugins}{ElasticModel}{global_scope}  = 1;
    config->{plugins}{ElasticModel}{request_scope} = 1;
}

use Dancer::Plugin::ElasticModel;

my $request;
get '/' => sub {
    $request = emodel->current_scope;
    return 'OK';
};

ok my $global = emodel->current_scope, 'Has global scope';
response_status_is [ GET => '/' ], 200, 'Request OK';

ok $request, 'Has request scope';
is $request->parent, $global, 'Global scope is parent to request';
my $old_req = "$request";
undef $request;

is emodel->current_scope, $global, 'Current scope is global';

response_status_is [ GET => '/' ], 200, 'Request OK';
ok $request = emodel->current_scope, 'Has new request scope';
is $request->parent, $global, 'Global scope is parent to new request';
ok $request ne $old_req, 'New request scope is different from old';
undef $request;

is emodel->current_scope, $global, 'Current scope is global';
