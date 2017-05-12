### install ###

    $ cpanm AnyEvent::Campfire::Client

### usage ###

```perl
use AnyEvent::Campfire::Client;
my $client = AnyEvent::Campfire::Client->new(
    token => 'xxxx',
    rooms => '1234',
    account => 'p5-hubot',
);

$client->on(
    'join',
    sub {
        my ($e, $data) = @_;    # $e is event emitter. please ignore it.
        $client->speak($data->{room_id}, "hi");
    }
);

$client->on(
    'message',
    sub {
        my ($e, $data) = @_;
        # ...
    }
);

## want to exit?
$client->exit;
```
