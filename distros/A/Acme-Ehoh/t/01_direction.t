use strict;
use Test::More tests => 10;

use Acme::Ehoh;

is(Acme::Ehoh::direction(2010), 255);
is(Acme::Ehoh::direction(2011), 165);
is(Acme::Ehoh::direction(2012), 345);
is(Acme::Ehoh::direction(2013), 165);
is(Acme::Ehoh::direction(2014), 75);
is(Acme::Ehoh::direction(2015), 255);
is(Acme::Ehoh::direction(2016), 165);
is(Acme::Ehoh::direction(2017), 345);
is(Acme::Ehoh::direction(2018), 165);
is(Acme::Ehoh::direction(2019), 75);
