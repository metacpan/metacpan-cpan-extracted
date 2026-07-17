use v5.36;
use Test::More;
use Catalyst::Plugin::JSONRPC::Server::Dispatcher;

my @seen;
my $d = Catalyst::Plugin::JSONRPC::Server::Dispatcher->new;
$d->register( note => sub ($p) { push @seen, $p; return 'ignored' } );
$d->register( sum  => sub ($p) { my $t = 0; $t += $_ for @$p; $t } );
$d->register( boom => sub ($p) { die "x\n" } );

# A lone notification: handler runs, but nothing is returned.
is( $d->dispatch('{"jsonrpc":"2.0","method":"note","params":[42]}'),
    undef, 'notification yields no response' );
is_deeply( \@seen, [ [42] ], 'but the handler did run' );

# Notification to an unknown method / dying handler still yields nothing.
is( $d->dispatch('{"jsonrpc":"2.0","method":"nope"}'),       undef,
    'notification to unknown method: silent' );
is( $d->dispatch('{"jsonrpc":"2.0","method":"boom"}'),       undef,
    'notification whose handler dies: silent' );

# Batch: mix of calls and notifications -> only the calls respond, in order.
# Includes a notification in the MIDDLE and a TRAILING notification, so a
# trailing-undef / array-append off-by-one would be caught.
my $batch = $d->dispatch( <<'JSON' );
[
  {"jsonrpc":"2.0","method":"sum","params":[1,2,4],"id":1},
  {"jsonrpc":"2.0","method":"note","params":["hi"]},
  {"jsonrpc":"2.0","method":"nope","id":2},
  {"jsonrpc":"2.0","method":"note","params":["bye"]}
]
JSON
is_deeply(
    $batch,
    [
        { jsonrpc => '2.0', result => 7, id => 1 },
        { jsonrpc => '2.0', error => { code => -32601, message => 'Method not found' }, id => 2 },
    ],
    'batch returns only non-notification responses, in order (trailing note dropped)'
);

# A batch of only notifications -> nothing to send.
is(
    $d->dispatch('[{"jsonrpc":"2.0","method":"note","params":[1]},{"jsonrpc":"2.0","method":"note","params":[2]}]'),
    undef,
    'all-notification batch yields no response'
);

# Empty batch -> single Invalid Request.
is_deeply( $d->dispatch('[]'),
    { jsonrpc => '2.0', error => { code => -32600, message => 'Invalid Request' }, id => undef },
    'empty batch is invalid' );

done_testing;
