package Foo;
use Class::Spiffy -base;

package autouse;

use Test::More tests => 1;

is 'Foo'->can('import'), \&Exporter::import,
    'Class::Spiffy modules support autouse';
