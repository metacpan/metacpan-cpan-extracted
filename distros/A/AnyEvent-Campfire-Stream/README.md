### install ###

    $ cpanm AnyEvent::Campfire::Stream

### usage ###

```perl
use AnyEvent::Campfire::Stream;
my $stream = AnyEvent::Campfire::Stream->new(
    token => 'xxx',
    rooms => '1234',    # hint: room id is in the url
                        # seperated by comma `,`
);

$stream->on('stream', sub {
    my ($s, $data) = @_;    # $s is $stream
    # do something with $data
    print "$data->{id}: $data->{body}\n";
});

$stream->on('error', sub {
    my ($s, $error) = @_;
    # do something with $error
    print STDERR "$error\n";
});
```
