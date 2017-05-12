use strict;
use warnings;
use Test::More;
use Data::Compare::Module;

subtest 'no args' => sub {
    my $obj = Data::Compare::Module->new();
    isa_ok $obj, 'Data::Compare::Module';
};

subtest '2 modules' => sub {
    my $obj = Data::Compare::Module->new('ModA', 'ModB');
    isa_ok $obj, 'Data::Compare::Module';
};

done_testing;
