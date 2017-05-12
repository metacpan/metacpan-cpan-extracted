package TestApp;
our $VERSION = '0.100330';
use strict;
use warnings;

use Catalyst qw/
    -Debug
    Devel::ModuleVersions
/;
use Test::MockObject;

my $mock = Test::MockObject->new();
$mock->set_false(qw/debug error fatal info warn/);
#__PACKAGE__->log($mock);
__PACKAGE__->setup;

1;
