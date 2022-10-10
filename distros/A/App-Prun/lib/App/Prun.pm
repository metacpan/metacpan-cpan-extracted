use strict;
use warnings;
package App::Prun;
$App::Prun::VERSION = '1.11';
use Moo;
use Storable qw( freeze );  # to support testing
use namespace::clean;

use 5.010;

has pm => ( is => 'ro', required => 1 );
has report_failed_procs => ( is => 'ro', default => 1 );
has exit_on_failed_proc => ( is => 'ro', default => 0 );

sub BUILD {
    my $self = shift;
    $self->pm->run_on_finish(sub{ $self->on_finish_callback(@_) });
    $self->pm->set_waitpid_blocking_sleep(0);
}

sub on_finish_callback {
    my $self = shift;
    my ($pid, $rc, $id, $sig, $core, $ref) = @_;

    if ($rc) {
        print STDERR "[$pid] Command '$id' failed with exit code $rc\n"
            if $self->report_failed_procs;

        return unless $self->exit_on_failed_proc;

        $self->pm->wait_all_children;
        exit 1;
    }
}

sub run_command {
    my $self = shift;
    my $cmd = shift;

    chomp $cmd;

    # Skip blank lines and comments
    return if (/^\s*(#|$)/);

    $self->pm->start($cmd) and return;

    # In the child now

    my $rc = system($cmd);
    $self->pm->finish($rc >> 8);
}

sub done { shift->pm->wait_all_children }

sub _test_dump {
    $Storable::forgive_me = 1;
    print freeze(shift);
    exit 255;
}

# ABSTRACT: Provides the prun script as a command line interface to L<Parallel::ForkManager>.
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prun - Provides the prun script as a command line interface to L<Parallel::ForkManager>.

=head1 VERSION

version 1.11

=head1 SYNOPSYS

    for nr in `seq 1..100`; do echo "echo command #$nr" | prun

    prun command_file_to_run_in_parallel

=head1 SEE ALSO

=over

=item L<prun>

=item prun --help

=back

=head1 REPOSITORY

The source repository for this module may be found at https://github.com/jmccarv/App-Prun.git

clone it:

  git clone https://github.com/jmccarv/App-Prun.git

=head1 AUTHOR

Jason McCarver <slam@parasite.cc>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Jason McCarver.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
