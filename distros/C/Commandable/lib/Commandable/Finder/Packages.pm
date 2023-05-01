#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2023 -- leonerd@leonerd.org.uk

package Commandable::Finder::Packages 0.10;

use v5.14;
use warnings;
use base qw( Commandable::Finder );

use Carp;

use Commandable::Command;
use Module::Pluggable::Object;

=head1 NAME

C<Commandable::Finder::Packages> - find commands stored per package

=head1 SYNOPSIS

   use Commandable::Finder::Packages;

   my $finder = Commandable::Finder::Packages->new(
      base => "MyApp::Command",
   );

   my $help_command = $finder->find_command( "help" );

   foreach my $command ( $finder->find_commands ) {
      ...
   }

=head1 DESCRIPTION

This implementation of L<Commandable::Finder> looks for implementations of
commands, where each command is implemented by a different package somewhere
in the symbol table.

This class uses L<Module::Pluggable> to load packages from the filesystem.
As commands are located per package (and not per file), the application can
provide special-purpose internal commands by implementing more packages in the
given namespace, regardless of which files they come from.

=head1 CONSTANTS

   package My::App::Commands::example;

   use constant COMMAND_NAME => "example";
   use constant COMMAND_DESC => "an example of a command";

   ...

Properties about each command are stored as methods (usually constant methods)
within each package. Often the L<constant> pragma module is used to create
them.

The following constant names are used by default:

=head2 COMMAND_NAME

   use constant COMMAND_NAME => "name";

Gives a string name for the command.

=head2 COMMAND_DESC

   use constant COMMAND_DESC => "description";

Gives a string description for the command.

=head2 COMMAND_ARGS

   use constant COMMAND_ARGS => (
      { name => "argname", description => "description" },
   );

Gives a list of command argument specifications. Each specification is a HASH
reference corresponding to one positional argument, and should contain keys
named C<name>, C<description>, and optionally C<optional>.

=head2 COMMAND_OPTS

   use constant COMMAND_OPTS => (
      { name => "optname", description => "description" },
   );

Gives a list of command option specifications. Each specification is a HASH
reference giving one named option, in no particular order, and should contain
keys named C<name>, C<description> and optionally C<mode>, C<multi> and
C<default>.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $finder = Commandable::Finder::Packages->new( %args )

Constructs a new instance of C<Commandable::Finder::Packages>.

Takes the following named arguments:

=over 4

=item base => STR

The base of the package namespace to look inside for packages that implement
commands.

=item name_method => STR

Optional. Gives the name of the method inside each command package to invoke
to generate the name of the command. Default C<COMMAND_NAME>.

=item description_method => STR

Optional. Gives the name of the method inside each command package to invoke
to generate the description text of the command. Default C<COMMAND_DESC>.

=item arguments_method => STR

Optional. Gives the name of the method inside each command package to invoke
to generate a list of argument specifications. Default C<COMMAND_ARGS>.

=item options_method => STR

Optional. Gives the name of the method inside each command package to invoke
to generate a list of option specifications. Default C<COMMAND_OPTS>.

=item code_method => STR

Optional. Gives the name of the method inside each command package which
implements the actual command behaviour. Default C<run>.

=item named_by_package => BOOL

Optional. If true, the name of each command will be taken from its package
name. with the leading C<base> string removed. If absent or false, the
C<name_method> will be used instead.

=back

If either name or description method are missing from a package, that package
is silently ignored.

Any additional arguments are passed to the C<configure> method to be used as
configuration options.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $base = ( delete $args{base} ) or croak "Require 'base'";

   my $name_method        = ( delete $args{name_method} )        // "COMMAND_NAME";
   my $description_method = ( delete $args{description_method} ) // "COMMAND_DESC";
   my $arguments_method   = ( delete $args{arguments_method} )   // "COMMAND_ARGS";
   my $options_method     = ( delete $args{options_method} )     // "COMMAND_OPTS";
   my $code_method        = ( delete $args{code_method} )        // "run"; # App-csvtool

   undef $name_method if delete $args{named_by_package};

   my $mp = Module::Pluggable::Object->new(
      search_path => $base,
      require     => 1,
   );

   my $self = bless {
      mp      => $mp,
      base    => $base,
      methods => {
         name => $name_method,
         desc => $description_method,
         args => $arguments_method,
         opts => $options_method,
         code => $code_method,
      },
   }, $class;

   $self->configure( %args ) if %args;

   return $self;
}

sub packages
{
   my $self = shift;

   my $name_method = $self->{methods}{name};

   my $packages = $self->{cache_packages} //= [ $self->{mp}->plugins ];

   return @$packages;
}

sub _commands
{
   my $self = shift;

   my $name_method = $self->{methods}{name};
   return $self->{cache_commands} //= do {
      my %commands;
      foreach my $pkg ( $self->packages ) {
         next if defined $name_method and not $pkg->can( $name_method );

         my $name = defined $name_method
            ? $pkg->$name_method
            : ( $pkg =~ s/\Q$self->{base}\E:://r );

         my $code = $pkg->can( $self->{methods}{code} ) or next;

         my $desc = ( $pkg->can( $self->{methods}{desc} ) or next )->( $pkg );

         my $args;
         if( my $argsmeth = $pkg->can( $self->{methods}{args} ) ) {
            $args = [
               map { Commandable::Command::_Argument->new( %$_ ) } $pkg->$argsmeth
            ];
         }

         my $opts;
         if( my $optsmeth = $pkg->can( $self->{methods}{opts} ) ) {
            $opts = {
               map { my $o = Commandable::Command::_Option->new( %$_ );
                     map { ( $_ => $o ) } $o->names
                   } $pkg->$optsmeth
            };
         }

         $commands{ $name } = Commandable::Command->new(
            name        => $name,
            description => $desc,
            arguments   => $args,
            options     => $opts,

            package => $pkg,
            code    => $code,
         );
      }

      $self->add_builtin_commands( \%commands );

      \%commands;
   };
}

sub find_commands
{
   my $self = shift;

   return values %{ $self->_commands };
}

sub find_command
{
   my $self = shift;
   my ( $cmd ) = @_;

   return $self->_commands->{$cmd};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
