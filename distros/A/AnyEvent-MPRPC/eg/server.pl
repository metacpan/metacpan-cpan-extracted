use strict;
use warnings;
use AnyEvent;
use AnyEvent::MPRPC::Server;

my $w = AnyEvent->signal( signal => 'PIPE', cb => sub { warn "SIGPIPE" } );

my $server = AnyEvent::MPRPC::Server->new(host => '127.0.0.1', port => 1984);
$server->reg_cb(
    sum => sub {
        my ($res_cv, $args) = @_;
        my $i = 0;
        $i += $_ for @$args;
        $res_cv->result( $i );
    },
);
AnyEvent->condvar->recv;

