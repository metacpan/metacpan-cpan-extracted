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
    plan tests => 15;
}

use Dancer::Plugin::ElasticModel;

is
    emodel->namespace('foo')->name,
    'foo',
    'Has namespace';

isa_ok
    emodel->es->transport,
    'Search::Elasticsearch::Transport',
    'Configured ES';

isa_ok my $domain = edomain('foo'), 'Elastic::Model::Domain', 'edomain';
is $domain->name, 'foo', 'edomain name';

isa_ok my $view = eview('user'), 'Elastic::Model::View', 'eview';
is_deeply $view->domain, ['foo'],  'View has domain foo';
is_deeply $view->type,   ['user'], 'View has type user';

isa_ok $view = eview( domain => 'foo', size => 1 ),
    'Elastic::Model::View',
    'Custom view';
is_deeply $view->domain, ['foo'], 'View has domain foo';
is_deeply $view->type, [], 'View has no type';
is $view->size, 1, 'View has size 1';

isa_ok $view = eview->domain('foo')->size(1),
    'Elastic::Model::View',
    'Custom chained view';
is_deeply $view->domain, ['foo'], 'View has domain foo';
is_deeply $view->type, [], 'View has no type';
is $view->size, 1, 'View has size 1';

