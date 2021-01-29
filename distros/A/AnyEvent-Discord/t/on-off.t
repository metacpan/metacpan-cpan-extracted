use v5.14;
use AnyEvent::Discord;
use Test::More tests => 7;

my $client = AnyEvent::Discord->new({ token => '', verbose => ($ENV{'AE_D_VERBOSE'} or 0) });

is( scalar(keys %{$client->_events}), 0, 'Verify empty events' );

my $simple = sub { return 1; };

$client->on('connect', $simple);
is( scalar(@{$client->_events->{'connect'}}), 1, 'on() Created connect event' );
is( $client->_events->{'connect'}->[0], $simple, 'Connect handler matches' );

$client->on('connect', $simple);
is( scalar(@{$client->_events->{'connect'}}), 1, 'on() Duplicate connect event does not add' );

$client->off('connect', sub { return 2; });
is( scalar(@{$client->_events->{'connect'}}), 1, 'off() Non-existent handler does not remove anything' );

$client->off('connect', $simple);
is( scalar(@{$client->_events->{'connect'}}), 0, 'off() Previous added handler is removed' );


$client->on('connect', $simple);
$client->off('connect');
is( $client->_events->{'connect'}, undef, 'off() without handler removes all from event' );

1;
