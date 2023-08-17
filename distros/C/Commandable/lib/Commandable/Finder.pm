#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package Commandable::Finder 0.11;

use v5.14;
use warnings;

use Carp;
use List::Util 'max';

require Commandable::Output;

=head1 NAME

C<Commandable::Finder> - an interface for discovery of L<Commandable::Command>s

=head1 SYNOPSIS

   use Commandable::Finder::...;

   my $finder = Commandable::Finder::...->new(
      ...
   );

   $finder->find_and_invoke( Commandable::Invocation->new( $text ) );

=head1 DESCRIPTION

This base class is common to the various finder subclasses:

=over 4

=item *

L<Commandable::Finder::SubAttributes>

=item *

L<Commandable::Finder::MethodAttributes>

=item *

L<Commandable::Finder::Packages>

=back

=head1 METHODS

=cut

=head2 configure

   $finder = $finder->configure( %conf )

Sets configuration options on the finder instance. Returns the finder instance
itself, to permit easy chaining.

The following configuration options are recognised:

=head3 allow_multiple_commands

If enabled, the L</find_and_invoke> method will permit multiple command
invocations within a single call.

=head3 require_order

If enabled, stop processing options when the first non-option argument
is seen.

=head3 bundling

If enabled, short (single-letter) options of simple boolean type can be
combined into a single C<-abc...> argument. Incrementable options can be
specified multiple times (as common with things like C<-vvv> for
C<--verbose 3>).

=cut

sub configure
{
   my $self = shift;
   my %conf = @_;

   exists $conf{$_} and $self->{config}{$_} = delete $conf{$_}
      for qw( allow_multiple_commands require_order bundling );

   keys %conf and croak "Unrecognised ->configure params: " . join( ", ", sort keys %conf );

   return $self;
}

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

If the C<allow_multiple_commands> configuration option is set, it will
repeatedly attempt to parse a command name followed by arguments and options
while the invocation string is non-empty.

=cut

sub find_and_invoke
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $multiple = $self->{config}{allow_multiple_commands};

   my $result;
   {
      defined( my $cmdname = $cinv->pull_token ) or
         die "Expected a command name\n";

      my $cmd = $self->find_command( $cmdname ) or
         die "Unrecognised command '$cmdname'";

      my @args = $cmd->parse_invocation( $cinv );

      !$multiple and length $cinv->peek_remaining and
         die "Unrecognised extra input: " . $cinv->peek_remaining . "\n";

      $result = $cmd->code->( @args );

      # TODO configurable separator - ';' or '|' or whatever
      #   currently blank

      redo if $multiple and length $cinv->peek_remaining;
   }

   return $result;
}

=head2 find_and_invoke_list

   $result = $finder->find_and_invoke_list( @tokens )

A further convenience around creating a L<Commandable::Invocation> from the
given list of values and using that to invoke a command.

=cut

sub find_and_invoke_list
{
   my $self = shift;

   require Commandable::Invocation;
   return $self->find_and_invoke( Commandable::Invocation->new_from_tokens( @_ ) );
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
   shift->find_and_invoke_list( @ARGV );
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

   Commandable::Output->printf( "%-*s%s%s\n",
      $max_len, $_->[0], $sep, $_->[1]
   ) for @rows;
}

# A join() that respects stringify overloading
sub _join
{
   my $sep = shift;
   my $ret = shift;
   $ret .= "$sep$_" for @_;
   return $ret;
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

   _print_table2 ": ", map {
      [ Commandable::Output->format_note( $_->name ), $_->description ]
   } @commands;
}

sub builtin_command_helpcmd
{
   my $self = shift;
   my ( $cmdname ) = @_;

   my $cmd = $self->find_command( $cmdname ) or
      die "Unrecognised command '$cmdname' - see 'help' for a list of commands\n";

   my @argspecs = $cmd->arguments;
   my %optspecs = $cmd->options;

   Commandable::Output->printf( "%s - %s\n",
      Commandable::Output->format_note( $cmd->name ),
      $cmd->description
   );
   Commandable::Output->printf( "\n" );

   Commandable::Output->print_heading( "SYNOPSIS:" );
   Commandable::Output->printf( "  %s\n",
      join " ",
         $cmd->name,
         %optspecs ? "[OPTIONS...]" : (),
         @argspecs ? (
            map { 
               my $argspec = $_;
               my $str = "\$" . uc $argspec->name;
               $str .= "..." if $argspec->slurpy;
               $str = "($str)" if $argspec->optional;
               $str;
            } @argspecs
         ) : ()
   );

   if( %optspecs ) {
      Commandable::Output->printf( "\n" );
      Commandable::Output->print_heading( "OPTIONS:" );

      # %optspecs contains duplicates; filter them
      my %primary_names = map { $_->name => 1 } values %optspecs;
      my @primary_optspecs = @optspecs{ sort keys %primary_names };

      my $first = 1;
      foreach my $optspec ( @primary_optspecs ) {
         Commandable::Output->printf( "\n" ) unless $first; undef $first;

         my $default = $optspec->default;
         my $value   = $optspec->mode eq "value" ? " <value>" : "";
         my $no      = $optspec->negatable       ? "[no-]"    : "";

         Commandable::Output->printf( "    %s\n",
            _join( ", ", map {
               Commandable::Output->format_note( length $_ > 1 ? "--$no$_$value" : "-$_$value", 1 )
            } $optspec->names )
         );
         Commandable::Output->printf( "      %s%s\n",
            $optspec->description,
            ( defined $default ? " (default: $default)" : "" ),
         );
      }
   }

   if( @argspecs ) {
      Commandable::Output->printf( "\n" );
      Commandable::Output->print_heading( "ARGUMENTS:" );

      _print_table2 "    ", map {
         [ "  " . Commandable::Output->format_note( '$' . uc $_->name, 1 ),
           $_->description ]
      } @argspecs;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
