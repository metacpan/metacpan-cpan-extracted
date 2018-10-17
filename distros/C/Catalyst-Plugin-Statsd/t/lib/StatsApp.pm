package StatsApp;

use Catalyst qw/ Statsd -Stats=1 /;

use MockStatsd;

use Test::Log::Dispatch;  # suppress stderr log

use namespace::autoclean;

__PACKAGE__->config(
    'psgi_middleware', [
        Statsd => {
            client => MockStatsd->new( autoflush => 1 ),
        },
    ],
);

__PACKAGE__->log( Test::Log::Dispatch->new );

__PACKAGE__->setup(
);


1;
