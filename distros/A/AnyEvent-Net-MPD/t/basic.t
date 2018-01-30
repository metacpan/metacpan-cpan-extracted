use Test::More;
use Test::Warnings;
use Try::Tiny;

use AnyEvent::Net::MPD;

ok my $mpd = AnyEvent::Net::MPD->new, 'constructor succeeds';

# Attributes
can_ok $mpd, $_ foreach qw( version auto_connect state password host port );

# Methods
can_ok $mpd, $_ foreach qw( send get idle noidle connect );

done_testing();
