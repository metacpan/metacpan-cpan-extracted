#!/usr/bin/perl

# this tests parallel execution

use strict;
use Test::More tests => 36;
use Config;
use Time::HiRes qw/usleep/;

SKIP: {
    skip "perl without ithreads",36 unless $Config{useithreads};
    use_ok('ChainMake::Parallel');

    my $cm;
    ok($cm=new ChainMake::Parallel(),'create ChainMake object');
    ok($cm->configure(
        verbose => 0,
        timestamps_file => 'test-parallel.stamps',
    ),'configure it');
    ok($cm->unlink_timestamps(),'clean timestamps');

    sub have_made_par {
        my ($number,$step)=@_;
        open OUT,">>","testout$number" or die "cannot open file for writing: $!";
        print OUT $step;
        close OUT;
        note "Have made $number.$step";
    }

    sub get_testout {
        my $num=shift;
        open IN,"<","testout$num" or die "cannot open file for reading: $!";
        my $res=join "", (<IN>);
        close IN;
        unlink "testout$num";
        return $res;
    }

    sub my_handler {
        my ($t_name,$t_base,$t_ext)=@_;
        have_made_par($t_base,$t_ext);
        1;
    }

    sub my_slow_handler {
        usleep(50000);
        my_handler(@_);
    }

    ok(($cm->targets(qr/^\d{3}\.1$/, (
        handler => \&my_slow_handler,
    ))), "target step 1");

    ok($cm->chainmake('001.1'),'Make target 001.1');
    ok(get_testout('001') eq '1','Did it right');

    ok(($cm->targets(qr/^\d{3}\.2$/, (
        requirements => ['$t_base.1'],
        handler => \&my_handler,
    ))), "target step 2");

    ok($cm->chainmake('001.2'),'Make target 001.2');
    ok(get_testout('001') eq '12','Did it right');

    ok(($cm->targets('test.A', (
        requirements => [map { "01$_.2" } (0..9)],
        handler      => \&my_handler,
    ))), "target test.A");

    ok($cm->chainmake('test.A'),'01x.2->test.A');
    for (0..9) {
        ok(get_testout("01$_") eq '12',"part 01$_ was made correctly");
    }
    ok(get_testout('test') eq 'A',"part test.A was made correctly");

    ok($cm->targets('test.B', (
        requirements => [map { "02$_.2" } (0..9)],
        parallel     => 3,
        handler      => \&my_handler,
    )), "parallel target test.B");

    ok($cm->chainmake('test.B'),'02x.2->test.B (parallel)');
    for (0..9) {
        ok(get_testout("02$_") eq '12',"part 02$_ was made correctly");
    }
    ok(get_testout('test') eq 'B',"part test.B was made correctly");
}
