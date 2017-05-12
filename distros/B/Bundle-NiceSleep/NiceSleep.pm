package Bundle::NiceSleep;

our $VERSION = '0.11';	

# as it just so turns out, the magic perdocs below actually contain
# the bundle info. Majique!

1;

__END__

=head1 NAME

Bundle::NiceSleep - NiceSleep-related functionality.

=head1 SYNOPSIS

 C<perl -MCPAN -e 'install Bundle::NiceSleep'> 

=head1 CONTENTS

Proc::NiceSleep         - sleep nice & smart

Proc::ProcessTable      - get info about the procs

Proc::Queue             - queue up processes, similar to below

Proc::Swarm             - handle a swarm of procs, similar to above 

Sys::CpuLoad            - allows simple reading of loads

Time::HiRes             - hi-res time() and sleep() 

=head1 DESCRIPTION

Modules that are useful for controlling a spate of server processes.

=head1 AUTHOR

Josh Rabinowitz, E<lt>joshr-proc-nicesleep@joshr.comE<gt>

=head1 SEE ALSO

L<Proc::NiceSleep>, L<Time::HiRes>, L<Proc::ProcessInfo>, L<Proc::Swarm>, 
L<Proc::Queue>, L<Sys::CpuLoad>.

=head1 LICENSE

Copyright (c) 2002 Josh Rabinowitz, All Right Reserved. Licensed the same as 
Perl itself.

=cut

