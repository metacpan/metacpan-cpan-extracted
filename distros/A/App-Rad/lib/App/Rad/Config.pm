package App::Rad::Config;

sub load_config {
    my ($c, @files) = (@_);

    foreach my $filename (@files) {

        $c->debug("loading configuration from $filename");
        open my $CONFIG, '<', $filename
            or Carp::croak "error opening $filename: $!\n";

        while (<$CONFIG>) {
            chomp;
            s/#.*//;
            s/^\s+//;
            s/\s+$//;
            next unless length;

            if ( m/^([^\=\:\s]+)        # key
                (?:                     # (value is optional)
                   (?:\s*[\=\:]\s*|\s+) # separator ('=', ':' or whitespace)
                   (.+)                 # value
                )?
                /x
            ) {
                $c->config->{$1} = $2;
            }
        }
        close $CONFIG;
    }
}

42;
