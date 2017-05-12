# t/03-limcase.t
use strict;
use warnings;
use Test::More;
use Data::CircularList;


subtest 'rotate == 1 case' => sub {
    my $list = Data::CircularList->new;
    my @num_vals = qw(20 15 18 37 3);
    
    for my $num_val (@num_vals) {
        $list->insert($num_val);
    }
    
    my $iter = $list->iterator( rotate => 1 );
    for my $num_val (sort { $a <=> $b } @num_vals) {
         if ($iter->has_next) {
             is $iter->next->data, $num_val;
         }
    }

    is $iter->has_next, 0;
};

subtest 'rotate == 2 case' => sub {
    my $list = Data::CircularList->new;
    my @num_vals = qw(20 15 18 37 3);
    
    for my $num_val (@num_vals) {
        $list->insert($num_val);
    }
    
    my $iter = $list->iterator( rotate => 2 );

    # 1st rotate
    for my $num_val (sort { $a <=> $b } @num_vals) {
         if ($iter->has_next) {
             is $iter->next->data, $num_val;
         }
    }

    is $iter->has_next, 1;

    # 2nd rotate
    for my $num_val (sort { $a <=> $b } @num_vals) {
         if ($iter->has_next) {
             is $iter->next->data, $num_val;
         }
    }

    is $iter->has_next, 0;
};

subtest 'rotate == 0 case' => sub {
    my $list = Data::CircularList->new;
    my @num_vals = qw(20 15 18 37 3);
    
    for my $num_val (@num_vals) {
        $list->insert($num_val);
    }
    
    my $iter = $list->iterator( rotate => 0 );

    is $iter->has_next, 0;
};

done_testing;

1;
