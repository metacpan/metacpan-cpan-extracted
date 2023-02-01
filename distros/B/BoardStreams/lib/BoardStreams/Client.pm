package BoardStreams::Client;

use Mojo::Base -strict, -signatures;

use BoardStreams::Client::Manager;

our $VERSION = "v0.0.32";

sub new ($class, @args) {
    return BoardStreams::Client::Manager->new(@args);
}

1;
