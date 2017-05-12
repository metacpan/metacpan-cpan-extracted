use Test::Exception tests => 1, import => ['!pass'];
use strict;
use warnings;

use lib 't/lib';
use Dancer ':syntax';
use Dancer::Test appdir => path( dirname($0), 'no_model', 'config.yml' );
use Dancer::Plugin::ElasticModel;

throws_ok
    sub { emodel->namespace },
    qr/Missing required setting \(model\)/,
    'No model';
