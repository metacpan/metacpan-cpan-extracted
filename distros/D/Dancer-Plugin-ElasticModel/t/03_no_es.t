use Test::More tests => 2, import => ['!pass'];
use strict;
use warnings;

use lib 't/lib';
use Dancer ':syntax';
use Dancer::Test appdir => path( dirname($0), 'no_es', 'config.yml' );
use Dancer::Plugin::ElasticModel;

is
    emodel->namespace('foo')->name,
    'foo',
    'Has namespace';

isa_ok
    emodel->es->transport,
    'Search::Elasticsearch::Transport',
    'Default ES';

