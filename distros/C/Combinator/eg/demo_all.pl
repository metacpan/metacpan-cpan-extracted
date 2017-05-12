#!/usr/bin/perl

use strict;
use warnings;
use Combinator verbose => 1;

use AE;

my $ser_done = AE::cv;
{{com
    print "Begin\n";
    my $a = 'a';
    my $t = AE::timer .5, 0, {{next}};

  --ser
    undef $t;
    print "First $a\n";
    my $b = 'b';

  --ser
    print "Second (no delay) $a $b\n";
    my $c = 'c';
    {{com
        print "Nest begin $a $b $c\n";
        my $t = AE::timer .5, 0, {{next}};
        my $d = 'd';
      --ser
        undef $t;
        print "Nest second $a $b $c $d\n";
        return;
      --ser
        print "Won't be here\n";
    }}com
    print "After nest begin\n";
  --ser
    print "Test par\n";

    for(0..4) {{com
        my $n = $_;
        my $delay = .5 - $_*.02;
        my $t = AE::timer $delay, 0, {{next}};
      --ser
        undef $t;
        print "par1 $n after $delay\n";
        {{next}}->($n); # push args to the next receiver
    }}com

    for(0..4) {{com
        my $n = $_;
        my $delay = $_*.02;
        my $t = AE::timer $delay, 0, {{next}};
      --ser
        undef $t;
        print "par2 $n after $delay\n";
        {{next}}->($n); # push args to the next receiver
    }}com

    my @nex;
    for(0..2) {{com
        my $n = $_;
        my $delay = .5 - $_*.03;
        my $t; $t = AE::timer $delay, 0, {{nex
            undef $t;
            $t = AE::timer .05, 0, {{next}};
            $delay += .05;
          --ser
            undef $t;
            $nex[$n] = $n;
            print "nex $n after $delay\n";
        }}nex;
    }}com

  --ser
    print "Done $a $b $c @nex @_\n"; # print the received args
    $ser_done->send;
}}com
$ser_done->recv;

my $par_cv = AE::cv;
{{com
    print "Jobs begin\n";
    {{com
        print "Job 1 begin\n";
        my $t = AE::timer 1, 0, {{next}};
      --ser
        undef $t;
        print "Job 1 done\n";
    --com
        print "Job 2 begin\n";
        my $t = AE::timer .5, 0, {{next}};
      --ser
        undef $t;
        print "Job 2 done\n";
    }}com
    print "Jobs begun\n";

    my $next = {{next}};
    $next->();
    $next->(); # next should be invoked only once
  --ser
    print "Jobs done\n";
    $par_cv->send;
}}com
$par_cv->recv;

my $cir_cv = AE::cv;
{{com
    my $n = 0;
    my $m = 0;
    {{cir
        ++$n;
        print "Cir1 $n begin\n";
        my $t = AE::timer .2, 0, {{next}};
      --ser
        undef $t;
        print "Cir1 $n second\n";
        my $t = AE::timer .2, 0, {{next}};
      --ser
        undef $t;
        return if( $n == 8 );
        print "Cir1 $n repeat\n";
    --com
        print "One shot!\n";
    --cir
        ++$m;
        print "Cir2 $m begin\n";
        my $t = AE::timer .5, 0, {{next}};
      --ser
        undef $t;
        print "Cir2 $m second\n";
        my $t = AE::timer .5, 0, {{next}};
      --ser
        undef $t;
        return if( $m == 3 );
        print "Cir2 $m repeat\n";
    }}com
--ser
    $cir_cv->send;
}}com
$cir_cv->recv;

=comment Expected Output

Begin
First a
Second (no delay) a b
Nest begin a b c
After nest begin
Nest second a b c d
Test par
par2 0 after 0
par2 1 after 0.02
par2 2 after 0.04
par2 3 after 0.06
par2 4 after 0.08
par1 4 after 0.42
par1 3 after 0.44
par1 2 after 0.46
par1 1 after 0.48
nex 2 after 0.49
par1 0 after 0.5
nex 1 after 0.52
nex 0 after 0.55
Done a b c 0 1 2 0 1 2 3 4 4 3 2 1 0
Jobs begin
Job 1 begin
Job 2 begin
Jobs begun
next should be invoked only once at demo_all.pl line 99.
Job 2 done
Job 1 done
Jobs done
Cir1 1 begin
One shot!
Cir2 1 begin
Cir1 1 second
Cir1 1 repeat
Cir1 2 begin
Cir2 1 second
Cir1 2 second
Cir1 2 repeat
Cir1 3 begin
Cir2 1 repeat
Cir2 2 begin
Cir1 3 second
Cir1 3 repeat
Cir1 4 begin
Cir1 4 second
Cir2 2 second
Cir1 4 repeat
Cir1 5 begin
Cir1 5 second
Cir2 2 repeat
Cir2 3 begin
Cir1 5 repeat
Cir1 6 begin
Cir1 6 second
Cir1 6 repeat
Cir1 7 begin
Cir2 3 second
Cir1 7 second
Cir1 7 repeat
Cir1 8 begin
Cir1 8 second

=cut
