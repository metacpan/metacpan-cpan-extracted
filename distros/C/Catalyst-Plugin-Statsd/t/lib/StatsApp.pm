package StatsApp;

use Catalyst qw/
  Statsd
  -Stats=1
 /;

use MockStatsd;

use Term::Size::Any qw();
use Test::Log::Dispatch;  # suppress stderr log

use namespace::autoclean;

__PACKAGE__->config(
    'psgi_middleware', [
        Statsd => {
            client => MockStatsd->new( autoflush => 1 ),
        },
    ],
    'Plugin::Statsd' => {
        disable_stats_report => 0,
    },
);

__PACKAGE__->log( Test::Log::Dispatch->new );

__PACKAGE__->setup(
);

sub sessionid {
    my $c = shift;
    return 1;
}

1;
