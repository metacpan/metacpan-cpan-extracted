package Class::Usul::Response::IPC;

use namespace::autoclean;

use Moo;
use Class::Usul::Types qw( Int Object Str Undef );

has 'core'    => is => 'ro', isa => Int, default => 0;
has 'harness' => is => 'ro', isa => Object | Undef;
has 'out'     => is => 'ro', isa => Str, default => q();
has 'pid'     => is => 'ro', isa => Int | Undef;
has 'rv'      => is => 'ro', isa => Int, default => 0;
has 'sig'     => is => 'ro', isa => Int | Undef;
has 'stderr'  => is => 'ro', isa => Str, default => q();
has 'stdout'  => is => 'ro', isa => Str, default => q();

1;

__END__

=pod

=head1 Name

Class::Usul::Response::IPC - Response class for running external programs

=head1 Synopsis

   use Class::Usul::Response::IPC;

   my $result = Class::Usul::Response::IPC->new();

=head1 Description

Response class returned by L<Class::Usul::IPC/run_cmd> and
L<Class::Usul::IPC/popen>

=head1 Configuration and Environment

This class defined these attributes:

=over 3

=item C<core>

True if external commands core dumped

=item C<harness>

The L<IPC::Run> harness object if one was used

=item C<out>

Processed output from the command

=item C<pid>

The id of the child process

=item C<sig>

Signal that caused the program to terminate

=item C<rv>

The return value of from running the command

=item C<stderr>

The standard error output from the command

=item C<stdout>

The standard output from the command

=back

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
