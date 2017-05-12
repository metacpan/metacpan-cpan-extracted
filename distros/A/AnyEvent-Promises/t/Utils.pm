package t::Utils;
use strict;
use warnings;

use Exporter 'import';
use AnyEvent;
use Test::More;

our @EXPORT = qw(run_event_loop el_subtest);

sub run_event_loop(&@) {
    my ( $code, %args ) = @_;

    my $timeout = defined $args{timeout}? $args{timeout}: 10;
    my $cv = AE::cv;
    my $tmer;
    $tmer
        = AE::timer( $timeout, 0, sub { undef $tmer; $cv->send('TIMEOUT') } );
    $code->($cv);
    $cv->recv;

    return $tmer ? 1: fail("Event loop failed");
}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

