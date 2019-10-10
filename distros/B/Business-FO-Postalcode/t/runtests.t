## no critic (RequireExplicitPackage RequireVersionVar RequireEndWithOne)

use strict;
use warnings;
use Test::Class;

use lib qw(t);

use Test::Class::Business::FO::Postalcode;
use Test::Class::Class::Business::FO::Postalcode;

Test::Class->runtests;
