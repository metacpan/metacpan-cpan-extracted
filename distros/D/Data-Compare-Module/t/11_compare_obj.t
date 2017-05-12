use strict;
use warnings;
use Test::More;
use Data::Compare::Module;

use lib 't/lib';

use ModA;
use ModB;
use ModC;

my $c1 = Data::Compare::Module->new();
is_deeply [$c1->compare('ModA', 'ModB')], [[ ], [ ]];
is_deeply [$c1->compare('ModA', 'ModC')], [[qw(bar)], [qw(bbr)]];

my $c2 = Data::Compare::Module->new('ModA', 'ModB');
is_deeply [$c2->compare], [[ ], [ ]];

my $c3 = Data::Compare::Module->new('ModA', 'ModC');
is_deeply [$c3->compare], [[qw(bar)], [qw(bbr)]];

# Overwrite
my $c4 = Data::Compare::Module->new('ModA', 'ModC');
is_deeply [$c2->compare('ModA', 'ModB')], [[ ], [ ]];

my $c5 = Data::Compare::Module->new('ModA', 'ModB');
is_deeply [$c5->compare('ModA', 'ModC')], [[qw(bar)], [qw(bbr)]];

# Reverse
is_deeply [$c1->compare('ModB', 'ModA')], [[ ], [ ]];
is_deeply [$c1->compare('ModC', 'ModA')], [[qw(bbr)], [qw(bar)]];

done_testing;
