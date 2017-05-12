# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Coro-DataPipe.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Coro;
use Coro::AnyEvent;
use Time::HiRes qw(time);

use Test::More tests => 7;
BEGIN { use_ok('Coro::DataPipe') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

test_run();
test_pipeline();

sub test_run {
    my $n_items = 5000;
    my $sleep = 0.01; # make $n_items * $sleep > 1 to test cooperative processing
    my @input = 1..$n_items;
    my @copy = @input;
    my @processed;
    my $t = time();
    my $number_of_data_processors = $n_items;#int($n_items/20);
    $number_of_data_processors = 367;
    Coro::DataPipe::run({
        input => \@input,
        process => sub{
            Coro::AnyEvent::sleep(rand() * $sleep);
            $_*2;
        },
        output=>\@processed,
        number_of_data_processors => $number_of_data_processors,
    });
    ok(time-$t<$n_items*($n_items/$number_of_data_processors)*$sleep,"*** run: cooperative processing of $n_items items by $number_of_data_processors data processors");
    ok(@processed==$n_items,'processed length');
    ok(join(",",map $_*2,@copy) eq join(",",sort {$a <=> $b} @processed),'processed values');
}

sub test_pipeline {
    my $n_items = 10000;
    my $sleep = 0.01; # make $n_items * $sleep > 1 to test cooperative processing
    my @input = 1..$n_items;
    my @copy = @input;
    my @processed;
    my $t = time();
    my $number_of_data_processors = $n_items;#int($n_items/20);
    $number_of_data_processors = 367;
    Coro::DataPipe::pipeline({
        input => \@input,
        process => sub{
            Coro::AnyEvent::sleep(rand() * $sleep);
            $_*2;
        },
        number_of_data_processors => $number_of_data_processors,
    },
    {
        process => sub{
            Coro::AnyEvent::sleep(rand() * $sleep);
            $_*3;
        },
        number_of_data_processors => $number_of_data_processors,
        output=>\@processed,
    },                        
    );
    ok(time-$t<$n_items*($n_items/$number_of_data_processors)*$sleep,"*** pipeline: cooperative processing of $n_items items by $number_of_data_processors data processors");
    ok(@processed==$n_items,'processed length');
    ok(join(",",map $_*6,@copy) eq join(",",sort {$a <=> $b} @processed),'processed values');    
}

