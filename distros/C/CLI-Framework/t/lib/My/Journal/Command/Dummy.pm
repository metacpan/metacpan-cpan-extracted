package My::Journal::Command::Dummy;

use strict;
use warnings;

sub new { bless {}, $_[0] }

1;

__END__

=pod

=head1 DUMMY CLASS

This is a dummy class that exists solely to demonstrate that (sub)command
directory hierarchies can contain classes that do NOT represent subcommands.
This class is ignored during construction of the command tree for the
My::Journal application because it does not inherit from
My::Journal::Command (even though it is in the expected directory location for
My::Journal::Command subclasses).

=cut
