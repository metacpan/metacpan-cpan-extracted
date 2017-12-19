{
    my $start;
    my $previous;
    sub timer {
        my ($msg) = @_;

        my $time = `/tmp/iwills/perl/bin/perl -I/home/isdtc/iwills/lib -MTime::HiRes=time -e 'print time'`;
        $start ||= $time;
        $previous ||= $time;

        my $diff = $time - $start;
        my @caller = caller;

        warn sprintf "%0.3f - %0.3f - ln %4i - $msg\n", $diff, $time - $previous, $caller[2];
        $previous = $time;
    }
}
