package CPAN::ParseDistribution::Unix;

use strict;
use warnings;

=head1 NAME

CPAN::ParseDistribution::Unix

=head1 DESCRIPTION

Unix-specific functionality

=cut

sub _run {
    my(undef, $safe_compartment, $code) = @_;
    my $result;
    my $fork_manager = Parallel::ForkManager->new(1);
    # to retrieve data returned from child
    $fork_manager->run_on_finish(sub { $result = $_[-1]; });

    # checking time instead of saying run_on_wait(..., 5) is because of
    # differences between 5.8.x and 5.18 (god knows when the difference came in)
    my($start_time, $timed_out, $pid) = (time(), 0);
    $fork_manager->run_on_wait(sub {
        if(time() - $start_time >= 5) {
	    $timed_out = 1;
	    kill(15, $pid);
	}
    }, 0.01);

    $pid = $fork_manager->start() || do {
        my $v = eval { $safe_compartment->reval($code) };
        if($@) { $result = { error => $@ }; }
         else { $result = { result => $v }; }
        $fork_manager->finish(0, $result);
    };
    $fork_manager->wait_all_children();
    $result->{error} = 'Safe compartment timed out' if($timed_out);
    return $result;
}

1;
