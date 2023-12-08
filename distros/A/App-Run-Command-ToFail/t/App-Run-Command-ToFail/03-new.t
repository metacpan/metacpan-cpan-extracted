use strict;
use warnings;

use App::Run::Command::ToFail;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = App::Run::Command::ToFail->new;
isa_ok($obj, 'App::Run::Command::ToFail');
