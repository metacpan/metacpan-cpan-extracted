use Test::More;
use Test::Warnings;
use Try::Tiny;

use AnyEvent::Net::MPD;

ok my $mpd = AnyEvent::Net::MPD->new, 'constructor succeeds';

# Attributes
can_ok $mpd, $_ foreach qw( version auto_connect state password host port );

# Methods
can_ok $mpd, $_ foreach qw( send get idle noidle connect );


SKIP: {
  my $connected = try { $mpd->connect };
  skip 'Cannot connect to MPD server', 3 unless $connected;

  ok $mpd->get('ping'), 'Blocking response to ping';
  my $send = $mpd->send('ping', sub {
    ok shift, 'Non-blocking response to ping';
  });
  ok $send->recv, 'Block until response to ping';
};

done_testing();
