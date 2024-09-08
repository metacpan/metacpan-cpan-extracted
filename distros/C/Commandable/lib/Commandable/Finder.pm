#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

package Commandable::Finder 0.14;

use v5.26;
use warnings;
use experimental qw( signatures );

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

   $finder = $finder->configure( %conf );

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

sub configure ( $self, %conf )
{
   exists $conf{$_} and $self->{config}{$_} = delete $conf{$_}
      for qw( allow_multiple_commands require_order bundling );

   keys %conf and croak "Unrecognised ->configure params: " . join( ", ", sort keys %conf );

   return $self;
}

=head2 add_global_options

   $finder->add_global_options( @optspecs );

I<Since version 0.13.>

Adds additional global options to the stored set.

Each is specified as a HASH reference containing keys to specify one option,
in the same style as the per-command options used by
L<Commandable::Finder::Packages>.

In addition, each should also provide a key named C<into>, whose value should
be a SCALAR or CODE reference to be used for applying the value for the option
when it is parsed. SCALAR references will be assigned to directly; CODE
references will be invoked with the option's name and value as positional
arguments:

   $$into = $value;
   $into->( $name, $value );

This style permits a relatively easy upgrade from such modules as
L<Getopt::Long>, to handle global options.

   GetOptions(
      'verbose|v+' => \my $VERBOSE,
      'silent|s'   => \my $SILENT,
   ) or exit 1;

Can now become

   $finder->add_global_options(
      { name => "verbose|v", mode => "inc", into => \my $VERBOSE,
         description => "Increase verbosity of output" },
      { name => "silent|s", into => \my $SILENT,
         description => "Silence output entirely" },
   );

with the added benefit of automated integration with the global C<help>
command, more consistent option parsing along with other command handling, and
so on.

=cut

sub add_global_options ( $self, @optspecs )
{
   foreach my $optspec ( @optspecs ) {
      my $into = $optspec->{into};
      my $opt = Commandable::Command::_Option->new( %$optspec );

      my $name = $opt->name;
      defined $into or
         croak "Global option $name requires an 'into'";
      ( ref $into ) =~ m/^(?:SCALAR|CODE)$/ or
         croak "Global option $name 'into' must be a SCALAR or CODE reference; got ";

      $self->{global_options}{ $_ } = $opt for $opt->names;
      $self->{global_options_into}{ $opt->keyname } = $into;
   }

   return $self;
}

=head2 handle_global_options

   $finder->handle_global_options( $cinv );

I<Since version 0.13.>

Extracts global options from the command invocation and process them into the
C<into> references previously supplied.

Normally it would not be necessary to invoke this directly, because the main
L</find_and_invoke> method does this anyway. It is provided in case the
implementing program performs its own command handling or changes the logic in
some other way.

=cut

sub handle_global_options ( $self, $cinv )
{
   my $global_optspecs = $self->{global_options}
      or return;

   my $opts = $self->parse_invocation_options( $cinv, $global_optspecs, passthrough => 1 );

   foreach ( keys %$opts ) {
      my $value = $opts->{$_};
      my $into = $self->{global_options_into}{$_};
      if( ref $into eq "SCALAR" ) {
         $into->$* = $value;
      }
      else {
         $into->( $_, $value );
      }
   }
}

=head2 find_commands

   @commands = $finder->find_commands;

Returns a list of command instances, in no particular order. Each will be an
instance of L<Commandable::Command>.

=head2 find_command

   $command = $finder->find_command( $cmdname );

Returns a command instance of the given name as an instance of
L<Commandable::Command>, or C<undef> if there is none.

=cut

=head2 parse_invocation

   @vals = $finder->parse_invocation( $command, $cinv );

I<Since version 0.12.>

Parses values out of a L<Commandable::Invocation> instance according to the
specification for the command's arguments. Returns a list of perl values
suitable to pass into the function implementing the command.

This method will throw an exception if mandatory arguments are missing.

=cut

sub parse_invocation ( $self, $command, $cinv )
{
   my @args;

   if( my %optspec = $command->options ) {
      push @args, $self->parse_invocation_options( $cinv, \%optspec );
   }

   foreach my $argspec ( $command->arguments ) {
      my $val = $cinv->pull_token;
      if( defined $val ) {
         if( $argspec->slurpy ) {
            my @vals = ( $val );
            while( defined( $val = $cinv->pull_token ) ) {
               push @vals, $val;
            }
            $val = \@vals;
         }
         push @args, $val;
      }
      elsif( !$argspec->optional ) {
         die "Expected a value for '".$argspec->name."' argument\n";
      }
      else {
         # optional argument was missing; this is the end of the args
         last;
      }
   }

   return @args;
}

sub parse_invocation_options ( $self, $cinv, $optspec, %params )
{
   my $passthrough = $params{passthrough};

   my $opts = {};
   my @remaining;

   while( defined( my $token = $cinv->pull_token ) ) {
      if( $token eq "--" ) {
         push @remaining, $token if $passthrough;
         last;
      }

      my $spec;
      my $value_in_token;
      my $token_again;

      my $value = 1;
      my $orig = $token;

      if( $token =~ s/^--([^=]+)(=|$)// ) {
         my ( $opt, $equal ) = ($1, $2);
         if( !$optspec->{$opt} and $opt =~ /no-(.+)/ ) {
            $spec = $optspec->{$1} and $spec->negatable
               or die "Unrecognised option name --$opt\n";
            $value = undef;
         }
         elsif( $spec = $optspec->{$opt} ) {
            $value_in_token = length $equal;
         }
         else {
            die "Unrecognised option name --$opt\n" unless $passthrough;
            push @remaining, $orig;
            next;
         }
      }
      elsif( $token =~ s/^-(.)// ) {
         unless( $spec = $optspec->{$1} ) {
            die "Unrecognised option name -$1\n" unless $passthrough;
            push @remaining, $orig;
            next;
         }
         if( $spec->mode_expects_value ) {
            $value_in_token = length $token;
         }
         elsif( $self->{config}{bundling} and length $token and length($1) == 1 ) {
            $token_again = "-$token";
            undef $token;
         }
      }
      else {
         push @remaining, $token;
         if( $self->{config}{require_order} ) {
            last;
         }
         else {
            next;
         }
      }

      my $name = $spec->name;

      if( $spec->mode_expects_value ) {
         $value = $value_in_token ? $token
                                  : ( $cinv->pull_token // die "Expected value for option --$name\n" );
      }
      else {
         die "Unexpected value for parameter $name\n" if $value_in_token or length $token;
      }

      if( defined( my $matches = $spec->matches ) ) {
         $value =~ $matches or
            die "Value for --$name option must " . $spec->match_msg . "\n";
      }

      my $keyname = $spec->keyname;

      if( $spec->mode eq "multi_value" ) {
         push $opts->{$keyname}->@*, $value;
      }
      elsif( $spec->mode eq "inc" ) {
         $opts->{$keyname}++;
      }
      elsif( $spec->mode eq "bool" ) {
         $opts->{$keyname} = !!$value;
      }
      else {
         $opts->{$keyname} = $value;
      }

      $token = $token_again, redo if defined $token_again;
   }

   $cinv->putback_tokens( @remaining );

   foreach my $spec ( values %$optspec ) {
      my $keyname = $spec->keyname;
      $opts->{$keyname} = $spec->default if
         defined $spec->default and !exists $opts->{$keyname};
   }

   return $opts;
}

=head2 find_and_invoke

   $result = $finder->find_and_invoke( $cinv );

A convenient wrapper around the common steps of finding a command named after
the initial token in a L<Commandable::Invocation>, parsing arguments from it,
and invoking the underlying implementation function.

If the C<allow_multiple_commands> configuration option is set, it will
repeatedly attempt to parse a command name followed by arguments and options
while the invocation string is non-empty.

=cut

sub find_and_invoke ( $self, $cinv )
{
   my $multiple = $self->{config}{allow_multiple_commands};

   # global options come first
   $self->handle_global_options( $cinv )
      if $self->{global_options};

   my $result;
   {
      defined( my $cmdname = $cinv->pull_token ) or
         die "Expected a command name\n";

      my $cmd = $self->find_command( $cmdname ) or
         die "Unrecognised command '$cmdname'";

      my @args = $self->parse_invocation( $cmd, $cinv );

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

   $result = $finder->find_and_invoke_list( @tokens );

A further convenience around creating a L<Commandable::Invocation> from the
given list of values and using that to invoke a command.

=cut

sub find_and_invoke_list ( $self, @args )
{
   require Commandable::Invocation;
   return $self->find_and_invoke( Commandable::Invocation->new_from_tokens( @args ) );
}

=head2 find_and_invoke_ARGV

   $result = $finder->find_and_invoke_ARGV();

A further convenience around creating a L<Commandable::Invocation> from the
C<@ARGV> array and using that to invoke a command. Often this allows an entire
wrapper script to be created in a single line of code:

   exit Commandable::Finder::SOMESUBCLASS->new( ... )
      ->find_and_invoke_ARGV();

=cut

sub find_and_invoke_ARGV ( $self )
{
   $self->find_and_invoke_list( @ARGV );
}

=head1 BUILTIN COMMANDS

The following built-in commands are automatically provided.

=cut

sub add_builtin_commands ( $self, $commands )
{
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
sub _print_table2 ( $sep, @rows )
{
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
descriptive text. If any global options have been registered, these are
described as well.

With a command name argument, prints more descriptive text about that command,
additionally detailing the arguments and options.

The package that implements a particular command can provide more output by
implementing a method called C<commandable_more_help>, which will take as a
single argument the name of the command being printed. It should make use of
the various printing methods in L<Commandable::Output> to generate whatever
extra output it wishes.

=cut

sub _print_optspecs ( $optspecs )
{
   # @optspecs may contain duplicates; filter them
   my %primary_names = map { $_->name => 1 } values %$optspecs;
   my @optspecs = @$optspecs{ sort keys %primary_names };

   my $first = 1;
   foreach my $optspec ( @optspecs ) {
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

sub builtin_command_helpsummary ( $self )
{
   my @commands = sort { $a->name cmp $b->name } $self->find_commands;

   Commandable::Output->print_heading( "COMMANDS:" );
   _print_table2 ": ", map {
      [ "  " . Commandable::Output->format_note( $_->name ), $_->description ]
   } @commands;

   if( my $opts = $self->{global_options} ) {
      Commandable::Output->printf( "\n" );
      Commandable::Output->print_heading( "GLOBAL OPTIONS:" );
      _print_optspecs( $opts );
   }
}

sub builtin_command_helpcmd ( $self, $cmdname )
{
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

      _print_optspecs( \%optspecs );
   }

   if( @argspecs ) {
      Commandable::Output->printf( "\n" );
      Commandable::Output->print_heading( "ARGUMENTS:" );

      _print_table2 "    ", map {
         [ "  " . Commandable::Output->format_note( '$' . uc $_->name, 1 ),
           $_->description ]
      } @argspecs;
   }

   my $cmdpkg = $cmd->package;
   if( $cmdpkg->can( "commandable_more_help" ) ) {
      $cmdpkg->commandable_more_help( $cmdname );
   }

   return 0;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
