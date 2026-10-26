{
    use v5.40;
    use blib;
    use Acme::Parataxis qw[async fiber yield];
    use Acme::Parataxis::Channel;
    #
    my $chan = Acme::Parataxis::Channel->new( capacity => 4 );
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
