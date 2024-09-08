#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

package Commandable::Finder::SubAttributes 0.14;

use v5.26;
use warnings;
use experimental qw( signatures );
use base qw( Commandable::Finder );

use Carp;

use Commandable::Command;

use constant HAVE_ATTRIBUTE_STORAGE => eval {
   require Attribute::Storage;
   Attribute::Storage->VERSION( '0.12' );
};

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

   :Command_description("description text")

Gives a plain string description text for the command.

=head2 Command_arg

   :Command_arg("argname", "description")

Gives a named argument for the command and its description.

If the name is suffixed by a C<?>, this argument is optional. (The C<?> itself
will be removed from the name).

If the name is suffixed by C<...>, this argument is slurpy. (The C<...> itself
will be removed from the name).

=head2 Command_opt

   :Command_opt("optname", "description")

   :Command_opt("optname", "description", "default")

Gives a named option for the command and its description.

If the name contains C<|> characters it provides multiple name aliases for the
same option.

If the name field ends in a C<=> character, a value is expected for the
option. It can either be parsed from the next input token, or after an C<=>
sign of the same token:

   --optname VALUE
   --optname=VALUE

If the name field ends in a C<@> character, a value is expected for the option
and can be specified multiple times. All the values will be collected into an
ARRAY reference.

If the name field ends in a C<+> character, the option can be specified
multiple times and the total count will be used as the value.

If the name field ends in a C<!> character, the option is negatable. An option
name of C<--no-OPTNAME> is recognised and will reset the value to C<undef>. By
setting a default of some true value (e.g. C<1>) you can detect if this has
happened.

An optional third argument may be present to specify a default value, if not
provided by the invocation.

=head1 GLOBAL OPTION ATTRIBUTES

I<Since version 0.14> this module also allows attaching attributes to package
variables in the package that stores the subroutines (often C<main>), which
will then be handled automatically as global options by the finder.

Remember that these have to be I<package> variables (i.e. declared with
C<our>); lexical variables (declared with C<my>) will not work.

   our $VERBOSE
      :GlobalOption("verbose|v+", "Increase the verbosity of status output");

This often serves as a convenient alternative to modules like L<Getopt::Long>,
because it integrates with the C<help> command automatically.

=head2 GlobalOption

   :GlobalOption("optname", "description")

Gives the name for this global option and its description. These are handled
in the same way as for L</Command_opt> given above, except that no default is
handled here. Instead, if the variable already has a value that will be taken
as its default.

=cut

sub import ( $pkg, @syms )
{
   my $caller = caller;

   foreach ( @syms ) {
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

   $finder = Commandable::Finder::SubAttributes->new( %args )

Constructs a new instance of C<Commandable::Finder::SubAttributes>.

Takes the following named arguments:

=over 4

=item package => STR

The name of the package to look in for command subs.

=item name_prefix => STR

Optional. Gives the name prefix to use to filter for subs that actually
provide a command, and to strip off to find the name of the command. Default
C<command_>.

=item underscore_to_hyphen => BOOL

Optional. If true, sub names that contain underscores will be converted into
hyphens. This is often useful in CLI systems, allowing commands to be typed
with hyphenated names (e.g. "get-thing") while the Perl sub that implements it
is named with an underscores (e.g. "command_get_thing"). Defaults true, but
can be disabled by passing a defined-but-false value such as C<0> or C<''>.

=back

Any additional arguments are passed to the C<configure> method to be used as
configuration options.

=cut

sub new ( $class, %args )
{
   HAVE_ATTRIBUTE_STORAGE or
      croak "Cannot create a $class as Attribute::Storage is not available";

   my $package = ( delete $args{package} ) or croak "Require 'package'";

   my $name_prefix = ( delete $args{name_prefix} )          // "command_";
   my $conv_under  = ( delete $args{underscore_to_hyphen} ) // 1;

   my $self = bless {
      package     => $package,
      name_prefix => $name_prefix,
      conv_under  => $conv_under,
   }, $class;

   $self->configure( %args ) if %args;

   # TODO: This package name should probably be separately configurable
   if( my %global_opts = Attribute::Storage::find_vars_with_attr( $package, "GlobalOption" ) ) {
      foreach my $varname ( sort keys %global_opts ) {
         my $varref = $global_opts{$varname};

         my $optspec = Attribute::Storage::get_varattr( $varref, "GlobalOption" );
         my ( $name, $description ) = @$optspec;

         my %optspec = (
            name        => $name,
            description => $description,
            into        => $varref,
         );

         $optspec{default} = $$varref if defined $$varref;

         $self->add_global_options( \%optspec );
      }
   }

   return $self;
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

sub new_for_caller ( $class, @args )
{
   return $class->new( package => scalar caller, @args );
}

sub new_for_main ( $class, @args )
{
   return $class->new( package => "main", @args );
}

sub _wrap_code ( $self, $code )
{
   return $code;
}

sub _commands ( $self )
{
   my $prefix = qr/$self->{name_prefix}/;

   my %subs = Attribute::Storage::find_subs_with_attr(
      $self->{package}, "Command_description",
      matching => qr/^$prefix/,
   );

   my %commands;

   foreach my $subname ( keys %subs ) {
      my $code = $subs{$subname};

      my $name = $subname =~ s/^$prefix//r;
      $name =~ s/_/-/g if $self->{conv_under};

      my $args;
      if( $args = Attribute::Storage::get_subattr( $code, "Command_arg" ) ) {
         $args = [ map { Commandable::Command::_Argument->new( %$_ ) } @$args ];
      }

      my $opts;
      if( $opts = Attribute::Storage::get_subattr( $code, "Command_opt" ) ) {
         $opts = { map { my $o = Commandable::Command::_Option->new( %$_ );
                         map { ( $_ => $o ) } $o->names
                       } @$opts };
      }

      $commands{ $name } = Commandable::Command->new(
         name        => $name,
         description => Attribute::Storage::get_subattr( $code, "Command_description" ),
         arguments   => $args,
         options     => $opts,
         package     => $self->{package},
         code        => $self->_wrap_code( $code ),
      );
   }

   $self->add_builtin_commands( \%commands );

   return \%commands;
}

sub find_commands ( $self )
{
   return values $self->_commands->%*;
}

sub find_command ( $self, $cmd )
{
   return $self->_commands->{$cmd};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
