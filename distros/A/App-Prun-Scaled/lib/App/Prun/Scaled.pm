package App::Prun::Scaled;

use 5.010_001;
use parent 'App::Prun';

our $VERSION = '1.06';

1;

__END__

=pod

=head1 NAME

App::Prun::Scaled - Provides the sprun script as a command line interface to L<Parallel::ForkManager::Scaled>.

=head1 VERSION

Version 1.05

=head1 SYNOPSYS

    for nr in `seq 1 100`; do echo "echo command #$nr" | sprun

    sprun command_file_to_run_in_parallel

=head1 DESCRIPTION

sprun allows you to utilize multiple CPUs for some workloads from 
the shell more easily.

sprun takes a list of commands (stdin and/or from file(s)) and run the commands
in parallel.

sprun is a CLI front end to L<Paralell::ForkManager::Scaled>. It runs commands
in parallel while trying to keep the CPUs at a specified level of activity by
constantly adjusting the number of running processes.

=over

=item * sprun --help

=item * L<Parallel::ForkManager::Scaled>

=back

=head1 EXAMPLES

There are also examples available from the command line B<--help>.

Run tkprof against all .trc files in the current directory
while attempting to keep the system 75% idle, don't adjust the
number of processes unless idle time goes below 74 or above 76, and
re-evaluate after each process exits (update frequency = 0).

  for F in *.trc; do echo "tkprof $F ${F%trc}txt"; done | sprun -t 75 -T 2 -u 0

Run all commands in a file (command_file), one line at a time.  Manually
bound the minimum and maximum number of processes to run and start with 4.
Keep the CPU 100% busy (0% idle) and re-evaluate at most every 3 seconds.
Ignore any failed processes, but do report to STDOUT any that fail.

  sprun -e -r -m 2 -M 8 -i 4 -u 3 command_file

Test with the dummy_load script included in the contrib/ directory 
of this distribution:

  for F in `seq 1 100`; do echo "contrib/dummy_load"; done | sprun -v

=head1 AUTHOR

Jason McCarver <slam@parasite.cc>

=head1 SEE ALSO

=over

=item L<App::Prun>

=item L<Parallel::ForkManager>

=item L<Parallel::ForkManager::Scaled>

=back

=head1 REPOSITORY

The mercurial repository for this module may be found here:

  https://bitbucket.org/jmccarv/app-prun-scaled

clone it:

  hg clone https://bitbucket.org/jmccarv/app-prun-scaled


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jason McCarver

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
