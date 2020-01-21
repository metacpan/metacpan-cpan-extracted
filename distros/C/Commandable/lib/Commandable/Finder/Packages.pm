#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Commandable::Finder::Packages;

use strict;
use warnings;
use 5.014; # s///r

our $VERSION = '0.04';

use Carp;

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

=item named_by_package => BOOL

Optional. If true, the name of each command will be taken from its package
name. with the leading C<base> string removed. If absent or false, the
C<name_method> will be used instead.

=back

If either name or description method are missing from a package, that package
is silently ignored.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $base = $args{base} or croak "Require 'base'";

   my $name_method        = $args{name_method}        // "COMMAND_NAME";
   my $description_method = $args{description_method} // "COMMAND_DESC";

   undef $name_method if $args{named_by_package};

   my $mp = Module::Pluggable::Object->new(
      search_path => $base,
      require     => 1,
   );

   return bless {
      mp      => $mp,
      base    => $base,
      methods => {
         name => $name_method,
         desc => $description_method,
      },
   }, $class;
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

         my $desc = ( $pkg->can( $self->{methods}{desc} ) or next )->( $pkg );

         $commands{ $name } = Commandable::Finder::Packages::_Command->new(
            name        => $name,
            description => $desc,

            package => $pkg,
         );
      }
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

package # hide
   Commandable::Finder::Packages::_Command;

sub new
{
   my $class = shift;
   my %args = @_;
   bless [ @args{qw( name description package )} ], $class;
}

sub name        { shift->[0] }
sub description { shift->[1] }

sub package { shift->[2] }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
