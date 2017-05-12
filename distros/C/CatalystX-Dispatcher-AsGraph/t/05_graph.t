use strict;
use warnings;
use Test::More tests => 1;
use lib ('t/lib');
use CatalystX::Dispatcher::AsGraph;

my $graph = CatalystX::Dispatcher::AsGraph->new(
    appname => 'TestApp',
    output  => 'test'
);
$graph->run;
is $graph->graph->as_txt, <<'...';
[ / ] --> [ \[action\] edit ]
[ / ] --> [ \[action\] index ]
[ / ] --> [ \[action\] root ]
[ / ] --> [ \[action\] view ]
[ / ] --> [ \[action\] view_user ]
...
