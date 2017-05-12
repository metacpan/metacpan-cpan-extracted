use strict;
use warnings;

use Test::More tests => 2, import => ['!pass'];
use Dancer;

ok( setting('appdir'), 'Complete import' );
use_ok 'Dancer::Plugin::ElasticModel';
diag(
    "Testing Dancer::Plugin::ElasticModel $Dancer::Plugin::ElasticModel::VERSION, Perl $], $^X"
);

