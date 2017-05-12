# t/01-new.t
use strict;
use warnings;
use Test::More;
use Data::CircularList;

my $list = Data::CircularList->new;
isa_ok $list, 'Data::CircularList';

done_testing;
