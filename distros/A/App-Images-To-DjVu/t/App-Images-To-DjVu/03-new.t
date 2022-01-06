use strict;
use warnings;

use App::Images::To::DjVu;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Images::To::DjVu->new;
isa_ok($obj, 'App::Images::To::DjVu');
