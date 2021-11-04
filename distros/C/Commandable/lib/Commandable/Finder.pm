#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Commandable::Finder 0.05;

use v5.14;
use warnings;

use List::Util 'max';

=head1 NAME

C<Commandable::Finder> - an interface for discovery of L<Commandable::Command>s

=head1 METHODS

=cut

=head2 find_commands

   @commands = $finder->find_commands

Returns a list of command instances, in no particular order. Each will be an
instance of L<Commandable::Command>.

=head2 find_command

   $command = $finder->find_command( $cmdname )

Returns a command instance of the given name as an instance of
L<Commandable::Command>, or C<undef> if there is none.

=cut

=head2 find_and_invoke

   $result = $finder->find_and_invoke( $cinv )

A convenient wrapper around the common steps of finding a command named after
the initial token in a L<Commandable::Invocation>, parsing arguments from it,
and invoking the underlying implementation function.

=cut

sub find_and_invoke
{
   my $self = shift;
   my ( $cinv ) = @_;

   defined( my $cmdname = $cinv->pull_token ) or
      die "Expected a command name\n";

   my $cmd = $self->find_command( $cmdname ) or
      die "Unrecognised command '$cmdname'";

   my @args = $cmd->parse_invocation( $cinv );

   length $cinv->peek_remaining and
      die "Unrecognised extra input: " . $cinv->peek_remaining . "\n";

   return $cmd->code->( @args );
}

=head2 find_and_invoke_ARGV

   $result = $finder->find_and_invoke_ARGV()

A further convenience around creating a L<Commandable::Invocation> from the
C<@ARGV> array and using that to invoke a command. Often this allows an entire
wrapper script to be created in a single line of code:

   exit Commandable::Finder::SOMESUBCLASS->new( ... )
      ->find_and_invoke_ARGV();

=cut

sub find_and_invoke_ARGV
{
   my $self = shift;

   require Commandable::Invocation;
   return $self->find_and_invoke( Commandable::Invocation->new_from_tokens( @ARGV ) );
}

=head1 BUILTIN COMMANDS

The following built-in commands are automatically provided.

=cut

sub add_builtin_commands
{
   my $self = shift;
   my ( $commands ) = @_;

   $commands->{help} =
      Commandable::Command->new(
         name => "help",
         description => "Display a list of available commands",
         arguments => [
            Commandable::Command::_Argument->new(
               name => "cmd",
               description => "command name",
               optional => 1,
            )
         ],
         code => sub {
            @_ ? return $self->builtin_command_helpcmd( @_ )
               : return $self->builtin_command_helpsummary;
         },
      );
}

# TODO: some pretty output formatting maybe using S:T:Terminal?
sub _print_table2
{
   my ( $sep, @rows ) = @_;

   my $max_len = max map { length $_->[0] } @rows;

   printf "%-*s%s%s\n",
      $max_len, $_->[0], $sep, $_->[1]
      for @rows;
}

=head2 help

   help

   help $commandname

With no arguments, prints a summary table of known command names and their
descriptive text.

With a command name argument, prints more descriptive text about that command,
additionally detailing the arguments.

=cut

sub builtin_command_helpsummary
{
   my $self = shift;

   my @commands = sort { $a->name cmp $b->name } $self->find_commands;

   _print_table2 ": ", map { [ $_->name, $_->description ] } @commands;
}

sub builtin_command_helpcmd
{
   my $self = shift;
   my ( $cmdname ) = @_;

   my $cmd = $self->find_command( $cmdname ) or
      die "Unrecognised command '$cmdname' - see 'help' for a list of commands\n";

   my @argspecs = $cmd->arguments;

   printf "%s - %s\n",
      $cmd->name, $cmd->description;

   printf "\nSYNOPSIS:\n";
   printf "  %s\n", join " ",
      $cmd->name,
      @argspecs ? ( map { "\$" . uc $_->name } @argspecs ) : ();

   if( @argspecs ) {
      print "\nARGUMENTS:\n";

      _print_table2 "    ", map {
         [ "  \$" . uc $_->name,
           $_->description ]
      } @argspecs;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
