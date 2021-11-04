#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Commandable::Finder::SubAttributes 0.05;

use v5.14;
use warnings;
use base qw( Commandable::Finder );

use Carp;

use Commandable::Command;

use constant HAVE_ATTRIBUTE_STORAGE => eval { require Attribute::Storage };

=head1 NAME

C<Commandable::Finder::SubAttributes> - find commands stored as subs with attributes

=head1 SYNOPSIS

   use Commandable::Finder::SubAttributes;

   my $finder = Commandable::Finder::SubAttributes->new(
      package => "MyApp::Commands",
   );

   my $help_command = $finder->find_command( "help" );

   foreach my $command ( $finder->find_commands ) {
      ...
   }

=head1 DESCRIPTION

This implementation of L<Commandable::Finder> looks for functions that define
commands, where each command is provided by an individual sub in a given
package.

=head1 ATTRIBUTES

   use Commandable::Finder::SubAttributes ':attrs';

   sub command_example
      :Command_description("An example of a command")
   {
      ...
   }

Properties about each command are stored as attributes on the named function,
using L<Attribute::Storage>.

The following attributes are available on the calling package when imported
with the C<:attrs> symbol:

=head2 Command_description

   :Command_description("name")

Gives a plain string description text for the command.

=head2 Command_arg

   :Command_arg("argname", "description")

Gives a named argument for the command and its description.

If the name is suffixed by a C<?> character, this argument is optional. (The
C<?> character itself will be removed from the name).

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   foreach ( @_ ) {
      if( $_ eq ":attrs" ) {
         HAVE_ATTRIBUTE_STORAGE or
            croak "Cannot import :attrs as Attribute::Storage is not available";

         require Commandable::Finder::SubAttributes::Attrs;
         Commandable::Finder::SubAttributes::Attrs->import_into( $caller );
         next;
      }

      croak "Unrecognised import symbol $_";
   }
}

=head1 CONSTRUCTOR

=cut

=head2 new

   $finder = Commandable::Finder::SubAttributes->mew( %args )

Constructs a new instance of C<Commandable::Finder::SubAttributes>.

Takes the following named arguments:

=over 4

=item package => STR

The name of the package to look in for command subs.

=item name_prefix => STR

Optional. Gives the name prefix to use to filter for subs that actually
provide a command, and to strip off to find the name of the command. Default
C<command_>.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   HAVE_ATTRIBUTE_STORAGE or
      croak "Cannot create a $class as Attribute::Storage is not available";

   my $package = $args{package} or croak "Require 'packaage'";

   my $name_prefix = $args{name_prefix} // "command_";

   return bless {
      package     => $package,
      name_prefix => $name_prefix,
   }, $class;
}

=head2 new_for_caller

=head2 new_for_main

   $finder = Commandable::Finder::SubAttributes->new_for_caller( %args )
   $finder = Commandable::Finder::SubAttributes->new_for_main( %args )

Convenient wrapper constructors that pass either the caller's package name or
C<main> as the package name. Combined with the C<find_and_invoke_ARGV> method
these are particularly convenient for wrapper scripts:

   #!/usr/bin/perl

   use v5.14;
   use warnings;

   use Commandable::Finder::SubAttributes ':attrs';

   exit Commandable::Finder::SubAttributes->new_for_main
      ->find_and_invoke_ARGV;

   # command subs go here...

=cut

sub new_for_caller
{
   my $class = shift;
   return $class->new( package => scalar caller, @_ );
}

sub new_for_main
{
   my $class = shift;
   return $class->new( package => "main", @_ );
}

sub _commands
{
   my $self = shift;

   my $prefix = qr/$self->{name_prefix}/;

   my %subs = Attribute::Storage::find_subs_with_attr(
      $self->{package}, "Command_description",
      matching => qr/^$prefix/,
   );

   my %commands;

   foreach my $subname ( keys %subs ) {
      my $code = $subs{$subname};

      my $name = $subname =~ s/^$prefix//r;

      my $args;
      if( $args = Attribute::Storage::get_subattr( $code, "Command_arg" ) ) {
         $args = [ map { Commandable::Command::_Argument->new( %$_ ) } @$args ];
      }

      $commands{ $name } = Commandable::Command->new(
         name        => $name,
         description => Attribute::Storage::get_subattr( $code, "Command_description" ),
         arguments   => $args,
         package     => $self->{package},
         code        => $code,
      );
   }

   $self->add_builtin_commands( \%commands );

   return \%commands;
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
