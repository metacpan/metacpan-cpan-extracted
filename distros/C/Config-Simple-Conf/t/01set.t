use strict;
  
use Test::More tests => 2;
use Config::Simple::Conf;

my $conf = Config::Simple::Conf->new;

isnt($conf->value($$, 'test'), 'this test should never fail');
$conf->set($$, 'test', 4321);
is($conf->value($$, 'test'), 4321, 'this should be 4321!');

