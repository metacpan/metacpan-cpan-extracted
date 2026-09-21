use blib;
{
    use v5.40;
    use Acme::Parataxis qw[:all];
    $|++;
    async {
        say 'Main task started';
        my $f1 = fiber {
            say '  Task 1: Sleeping...';
            await_sleep(1000);
            return 'Coffee!';
        };
        my $f2 = fiber {
            say '  Task 2: Calculating... (simulated CPU work)';
            my $sum = 0;
            for ( 1 .. 100 ) {
                $sum += $_;
                maybe_yield();    # Be a good neighbor
            }
            say '  Task 2: Complete. Will return ' . $sum;
            return $sum;
        };

        # 'await' works on fibers and futures
        say 'Result 1: ' . await($f1);
        say 'Result 2: ' . await($f2);
    };
}
