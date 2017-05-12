#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Dumper qw/Dumper/;

use App::MultiSsh qw/hosts_from_map/;

for my $data (good_data()) {
    is_deeply [hosts_from_map([$data->[0]])], $data->[1], "$data->[0] expands correctly"
        or diag Dumper [hosts_from_map([$data->[0]])], $data->[1];
}

done_testing();

sub good_data {
    return (
        # no change
        [ 'eg.com',           [qw/eg.com                                  /] ],
        # from doc examples
        [ 'eg[1..5].com',     [qw/eg1.com eg2.com eg3.com eg4.com eg5.com /] ],
        [ 'eg[1,5].com',      [qw/eg1.com                         eg5.com /] ],
        [ 'eg[1..3,5].com',   [qw/eg1.com eg2.com eg3.com         eg5.com /] ],
        [ 'eg[1-5].com',      [qw/eg1.com eg2.com eg3.com eg4.com eg5.com /] ],
        [ 'eg[1-3,5].com',    [qw/eg1.com eg2.com eg3.com         eg5.com /] ],
        [ 'eg{1..5}.com',     [qw/eg1.com eg2.com eg3.com eg4.com eg5.com /] ],
        [ 'eg{1,5}.com',      [qw/eg1.com                         eg5.com /] ],
        [ 'eg{1..3,5}.com',   [qw/eg1.com eg2.com eg3.com         eg5.com /] ],
        [ 'eg{1-5}.com',      [qw/eg1.com eg2.com eg3.com eg4.com eg5.com /] ],
        [ 'eg{1-3,5}.com',    [qw/eg1.com eg2.com eg3.com         eg5.com /] ],
        # two ranges
        [ 'eg[1-2][3-4].com', [qw/eg13.com eg14.com eg23.com eg24.com     /] ],
    );
}
