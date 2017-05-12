#!perl -w

use strict;
use Test::More tests => 16;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

my $j = 10;
my $x = run_block{
    my $i;
    for($i = 1; $i < 10; $i++){
        $j++;
    }
    return $i;
};
is $x, 10, 'for loop';
is $j, 19, 'for loop';

$x = run_block{
    my $c = 0;

    for(my $i = 0; $i < 10; $i++){
        for(my $j = 0; $j < 10; $j++){
            $c += 10;
        }
    }
    return $c;
};
is $x, 10*10*10, 'nested for loop';

$x = run_block{
    my $i = 0;
    while($i < 10){
        $i++;
    }
    return $i;
};
is $x, 10, 'while loop';
$x = run_block{
    my $c = 0;

    my $i = 0;
    while($i < 10){
        $i++;

        my $j = 0;
        while($j < 10){
            $j++;

            $c += 10;
        }
    }
    return $c;
};
is $x, 10*10*10, 'nested while loop';

$x = run_block{
    for(;;){
        return 42;
    }
};
is $x, 42, 'return in loop';

$x = run_block{
    my $i;
    for($i =0; $i < 10; $i++){
        last if $i == 5
    }
    return $i;
};
is $x, 5, 'last';

$x = run_block{
    my $i;
    {

        if($i){
            last;
        }
        else{
            $i = 42;
            redo;
        }
    }
    return $i;
};
is $x, 42, 'redo';

$x = run_block{
    my $j;
    while(!my $i){
        $i++;
        if($i == 5){
            $j = $i;
            last;
        }
        redo;
    }
    return $j;
};
is $x, 5, 'redo';

$x = run_block{
    my $j;
    for(my $i = 0; $i < 10; $i++){
        $j = $i;
        next;

        die;
    }
    return $j;
};
is $x, 9, 'next';

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
