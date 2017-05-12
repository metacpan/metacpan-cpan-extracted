use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

plan tests => 3;

use_ok('Catalyst::View::TT');
use_ok('Catalyst::Test', 'TestApp');

my $copy;
{
    my $view = new Catalyst::View::TT("TestApp", {});

    # Can't Test::Memory::Cycle test since it doesn't detect 
    #  [ sub { $copy->paths } ]
    # as a cycle, but the above does prevent it getting garbage collected.
    #
    # memory_cycle_ok($view, 'No cycles in View');

    $copy = $view;
    Scalar::Util::weaken($copy);
}

ok(!defined $copy, 'Copy went out of scope');

