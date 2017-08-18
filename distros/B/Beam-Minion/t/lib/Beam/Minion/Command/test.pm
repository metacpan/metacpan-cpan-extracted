package
    Beam::Minion::Command::test;

=head1 DESCRIPTION

This module is used by C<t/command.t> to check that command modules are
loaded and run correctly.

=cut

our @ARGS;
sub run { @ARGS = @_ }
1;
