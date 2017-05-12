#!perl -w

use strict;
use Test::More tests => 14;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

my $x = run_block{
    my $sum = 0;
    foreach my $i(1 .. 10){
        $sum += $i;
    }
    return $sum;
};
is $x, 55;

{
    local $TODO = 'itervar localization';
    $x = run_block{
        my $sum = 0;
        my $i   = 100;
        foreach $i(1 .. 10){
            $sum += $i;
        }
        return $sum + $i;
    };
    is $x, 55 + 100;
}

my @ary = (1 .. 10);
$x = run_block{
    my $sum = 0;
    foreach (@ary){
        $sum += $_;
    }
    return $sum;
};
is $x, 55;

$x = run_block{
    my $sum = 0;
    foreach my $i(reverse @ary){
        $sum += $i;
        last;
    }
    return $sum;
};
is $x, 10;

$x = run_block{
    my $sum = 0;
    foreach my $i(1, 2, 3, 4, 5){
        $sum += $i;
    }
    return $sum;
};
is $x, 15;

$x = run_block{
    my $sum = 0;
    foreach my $i(reverse(1, 2, 3, 4, 5)){
        $sum += $i;
        last;
    }
    return $sum;
};
is $x, 5;

$x = run_block{
    my %h = (foo => 10, bar => 20);
    my $sum = 0;
    foreach my $key(keys %h){
        $sum += $h{$key};
    }
    return $sum;
};
is $x, 30;


$x = run_block{
    my %h = (foo => 10, bar => 20);
    my $sum = 0;
    foreach my $val(values %h){
        $sum += $val;
    }
    return $sum;
};
is $x, 30;


is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
