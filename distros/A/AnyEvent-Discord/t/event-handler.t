use v5.14;
use AnyEvent::Discord;
use AnyEvent::Discord::Payload;
use Test::More tests => 4;

my $cb = sub {
  my ($client, $data, $op) = @_;
  is( $data->{set}, 1, $data->{msg} );
};

my $client = AnyEvent::Discord->new({ token => '', verbose => ($ENV{'AE_D_VERBOSE'} or 0) });
$client->_internal_events->{'fakeinternalevent'} = [$cb];
$client->on('fakeuserevent', $cb);
$client->_internal_events->{'fakeevent'} = [$cb];
$client->on('fakeevent', $cb);

$client->_handle_event(AnyEvent::Discord::Payload->from_hashref({
  op => 1,
  d  => {
    set => 1,
    msg => 'internal defined event fires'
  },
  t => 'fakeinternalevent'
}));
$client->_handle_event(AnyEvent::Discord::Payload->from_hashref({
  op => 1,
  d  => {
    set => 1,
    msg => 'user defined event fires'
  },
  t => 'fakeuserevent'
}));
$client->_handle_event(AnyEvent::Discord::Payload->from_hashref({
  op => 1,
  d  => {
    set => 1,
    msg => 'both defined event fires twice'
  },
  t => 'fakeevent'
}));
$client->_handle_event(AnyEvent::Discord::Payload->from_hashref({
  op => 1,
  d  => {
    set => 1,
    msg => 'user defined event fires'
  },
  t => 'notarealevent'
}));

1;
