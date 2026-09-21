{
    use v5.40;
    use blib;
    use Acme::Parataxis qw[async fiber yield];
    use Acme::Parataxis::Channel;

    # The classic producer/consumer demonstration first popularised by Coro
    # (eg/prodcons), now running on the real Coro::Channel-style module.
    # "get" blocks while the channel is empty, "put" blocks while it is
    # full; both park the current fiber until the other end catches up.
    my $chan = Acme::Parataxis::Channel->new(4);
    async {
        # Producers
        fiber {
            $chan->put("apple-$_") for 1 .. 4;
        };
        fiber {
            $chan->put("pear-$_") for 1 .. 4;
        };

        # Consumer
        for ( 1 .. 8 ) {
            my $item = $chan->get;
            say "consumed $item (queue now " . $chan->size . ')';
        }
    };
    say 'done';
}
