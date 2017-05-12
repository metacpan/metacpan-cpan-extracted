use strict;
use warnings;
use App::MadEye;
use Test::More tests => 1;

my $c = App::MadEye->new({config => { }});
$c->run();

ok $c->class_component_methods->{'run_job'}, 'loaded';

