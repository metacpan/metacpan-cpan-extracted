use strict;
use warnings FATAL => 'all';
use Carp::POE;
use POE;
use Test::More tests => 1;
use Test::Warn;
 
POE::Session->create(
    package_states => [
        main => [qw( _start first_event second_event)]
    ],
);

warnings_like { $poe_kernel->run() } [ qr/line 17/, qr/line 18/ ], 'Warnings';

sub _start {
    $_[KERNEL]->yield('first_event');   # line 17
    $_[KERNEL]->yield('second_event');  # line 18
}
 
sub first_event {
    carp 'Wrong';
}

sub second_event {
    carp 'Wrong';
}
