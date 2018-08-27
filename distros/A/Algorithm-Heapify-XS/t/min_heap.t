# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Algorithm-Heapify-XS.t'

#########################
use strict;
use warnings;

use Devel::Peek;
use Data::Dumper;

package OloadAry {
    use strict;
    use warnings;
    my $called= 0;
    use overload
        '<=>' => sub {
            $called++;
            my ($l,$r,$swap)= @_;
            ($l,$r)= ($r,$l) if $swap;
            if (ref($l) and ref($r)) {
                for my $i (0..$#$l) {
                    my $cmp= $r->[$i] <=> $l->[$i];
                    return $cmp if $cmp;
                }
                return 0;
            }
            ref($_) and $_= $_->[0]
                for $l, $r;
            return $r <=> $l;
        },
        fallback => 1,
    ;
    sub called_count { return $called }
    sub reset_called_count { my $old_called= $called; $called= 0; return $old_called; }
}

package main;
# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More;
use Time::HiRes qw(time);
use Algorithm::Heapify::XS ':all';
sub log2 {return log($_[0])/log(2)} 
my @test_tuples= (
    grep { $ENV{HARNESS_ACTIVE} ? ($_->[0]<100 && $_->[1]<1000) : 1 }
    (
        [10, 500],[20, 500],[40, 500],[80, 500], [100, 500], [ 500, 500],
        [10,1000],[20,1000],[40,1000],[80,1000], [100,1000], [1000,1000],
    )
);
plan tests => (@test_tuples * 3)+15;
my @n= reverse 1..10;
my $top;

$top= min_heapify(@n);
is($n[0],1,"min_heapify works");
is($top,1,"... and top looks ok");

$top= min_heap_push(@n,0);
is($n[0],0,"min_heap_push works");
is($top,0,"... and top looks ok");

$top= min_heap_push(@n,0.5);
is($n[0],0,"min_heap_push works");
is($top,0,"... and top looks ok");

$top= min_heap_shift(@n);
is($n[0],0.5,"min_heap_shift works");
is($top,0,"... and top looks ok");

$n[5]=-1;
$top= min_heap_adjust_item(@n,5);
is($n[0],-1,"min_heap_adjust_item works");
is($top,-1,"... and top looks ok");

$n[5]=1000;
$top= min_heap_adjust_item(@n,5);
is($n[0],-1,"min_heap_adjust_item works");
is($top,-1,"... and top looks ok");

$n[0]= 100;
$top= min_heap_adjust_top(@n);
is($n[0],0.5,"min_heap_adjust_top works");
is($top,0.5,"... and top looks ok");

my @expect= sort { $a<=>$b } @n;
my @got;
push @got, min_heap_shift(@n) while @n;
is("@got","@expect","and everything looks as expected at the end");


my @res;
foreach my $tuple (@test_tuples) {
    my $num_agents= $tuple->[0];
    my $num_jobs= $tuple->[1];

    my $agent_id= "AA";
    my @agents= map { $agent_id++ } 1 .. $num_agents;
    my $job_id= 1;
    my @jobs= map { $job_id++ } 1 .. $num_jobs;

    my %agent_array;
    my @arrays1;
    my @arrays2;
    my @sequence1;
    my @sequence2;
    foreach my $agent_id (@agents) {
        my @agent_jobs1;
        my @agent_jobs2;
        foreach my $job (@jobs) {
            my $j= bless [ int(rand(1000)), $job_id++ ], "OloadAry";
            push @agent_jobs1, $j;
            push @agent_jobs2, $j;

        }
        push @arrays1, bless \@agent_jobs1, "OloadAry";
        push @arrays2, bless \@agent_jobs2, "OloadAry";
        $agent_array{0+ $arrays1[-1]}= $agent_id;
        $agent_array{0+ $arrays2[-1]}= $agent_id;

    }

    my $min_heap_elapsed= 0 - time();
    {
        my $constructed_count;
        for (@arrays1) {
            min_heapify(@$_);
        }
        min_heapify(@arrays1);
        my %taken;
        while (@arrays1) {
            while (@arrays1 and $taken{$arrays1[0][0][1]}) {
                # note do { } means the condition fires after the statement
                do { min_heap_shift(@{$arrays1[0]}) } 
                    while (@{$arrays1[0]} and $taken{$arrays1[0][0][1]});

                if (@{$arrays1[0]}) {
                    min_heap_adjust_top(@arrays1);
                } else {
                    min_heap_shift(@arrays1);
                }
            }
            last unless @arrays1;

            my $best_ary= min_heap_shift(@arrays1);
            my $best_item= $best_ary->[0];
            my $job_id= $best_item->[1];
            my $agent= $agent_array{0+$best_ary};
            my $score= $best_item->[0];
            $taken{$job_id}++;
            push @sequence1, "$agent:$job_id";
        }
    }
    $min_heap_elapsed += time();
    my $min_heap_comparisons= OloadAry::reset_called_count();
    
    my $sort_elapsed= 0 - time();
    {
        @$_= sort { $a <=> $b } @$_ for @arrays2;
        @arrays2= sort { $a <=> $b } @arrays2;
        #die Data::Dumper::Dumper(\@arrays2);
        my %taken;
        while (@arrays2) {
            my $best_ary= shift @arrays2;
            last if !@$best_ary;
            my $best_item= shift @$best_ary;
            my $agent= $agent_array{0+$best_ary};
            my $score= $best_item->[0];
            my $job_id= $best_item->[1];
            push @sequence2, "$agent:$job_id";
            $taken{$job_id}++;
            foreach my $ary (@arrays2) {
                shift @$ary while @$ary and $taken{$ary->[0][1]};
            }
            @arrays2= sort { $a <=> $b } grep { 0+@$_ } @arrays2;
        }
    }
    $sort_elapsed += time();
    my $sort_comparisons= OloadAry::reset_called_count();
    my $worst_min_heap_comparisons= ($num_agents * (2*$num_jobs)) 
                              + (2*$num_agents) 
                              + ($num_agents * log2($num_agents)) 
                              + ($num_agents * log2($num_jobs));
    my $worst_sort_comparisons= $num_agents * $num_jobs * log2($num_jobs);
    push @res,[
        $num_jobs, $num_agents, 
        
        $min_heap_elapsed * 1000, 
        $min_heap_comparisons, 
        $worst_min_heap_comparisons,

        $sort_elapsed * 1000, 
        $sort_comparisons, 
        $worst_sort_comparisons, 
        
        $min_heap_comparisons / $sort_comparisons * 100,
        
    ];
    cmp_ok($min_heap_comparisons,"<",$sort_comparisons,"(a=$num_agents j=$num_jobs) min_heap took less comparisons");
    cmp_ok($min_heap_elapsed*1000,"<",$sort_elapsed*1000,"(a=$num_agents j=$num_jobs) min_heap took less time");
    is("@sequence1","@sequence2","(a=$num_agents j=$num_jobs) got same results");
}

my @title= qw(j a stook scmp a*j*log2(j) htook hcmp a2j+2a+a*log2(a)+a*log2(j) pct );
my $smax_len= length $title[4];
my $hmax_len= length $title[-2];
!$ENV{HARNESS_ACTIVE} && diag join "\n", 
    sprintf("%4s %4s | %7sms %8s %${smax_len}s | %7sms %8s %${hmax_len}s | %5s |",@title),
    map { sprintf("%4d %4d | %7.0fms %8d %${smax_len}.0f | %7.0fms %8d %${hmax_len}.0f | %5.2s |",@$_) } @res;




#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

