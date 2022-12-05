#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Commandable::Finder::MethodAttributes 0.09;

use v5.14;
use warnings;
use base qw( Commandable::Finder::SubAttributes );

use Carp;

=head1 NAME

C<Commandable::Finder::MethodAttributes> - find commands stored as methods with attributes

=head1 SYNOPSIS

   use Commandable::Finder::MethodAttributes;

   my $object = SomeClass->new( ... );

   my $finder = Commandable::Finder::MethodAttributes->new(
      object => $object,
   );

   my $help_command = $finder->find_command( "help" );

   foreach my $command ( $finder->find_commands ) {
      ...
   }

=head1 DESCRIPTION

This subclass of L<Commandable::Finder::SubAttributes> looks for methods that
define commands, where each command is provided by an individual method in a
given class. It stores the object instance and arranges that each discovered
command method will capture it, passing it as the first argument when invoked.

The attributes on each method are those given by
C<Commandable::Finder::SubAttributes> and are used in the same way here.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $finder = Commandable::Finder::MethodAttributes->new( %args )

Constructs a new instance of C<Commandable::Finder::MethodAttributes>.

Takes the following named arguments:

=over 4

=item object => OBJ

An object reference. Its class will be used for searching for command methods.
The instance itself is stored by the finder object and used to wrap each
command method.

=back

Any additional arguments are passed to the superclass constructor.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $object = delete $args{object} or croak "Require 'object'";
   $args{package} = ref $object;

   my $self = $class->SUPER::new( %args );

   $self->{object} = $object;

   return $self;
}

sub _wrap_code
{
   my $self = shift;
   my ( $code ) = @_;

   my $object = $self->{object};

   return sub {
      $object->$code( @_ );
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
