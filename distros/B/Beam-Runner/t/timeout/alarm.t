
=head1 DESCRIPTION

This file tests the L<Beam::Runnable::Timeout::Alarm> class to ensure it
times out correctly.

=head1 SEE ALSO

L<Beam::Runnable::Timeout::Alarm>

=cut

use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::Fatal;

my $RUNNING = 1;
{ package
        t::Timeout::Alarm;
    use Moo;
    with 'Beam::Runnable', 'Beam::Runnable::Timeout::Alarm';
    sub run {
        while ( $RUNNING ) { sleep 1 }
    }
}

subtest 'test timeout' => sub {
    my $flag = 0;
    my $foo = t::Timeout::Alarm->new(
        timeout => 0.1,
        _timeout_cb => sub {
            $RUNNING = 0;
        },
    );
    $foo->run;
    ok !$RUNNING, 'timeout reached';
};

done_testing;
